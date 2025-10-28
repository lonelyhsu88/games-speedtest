#!/usr/bin/env node

/**
 * Puppeteer Game Loading Test
 *
 * This script uses a real browser (Chromium) to test game loading
 * and captures ALL network requests including:
 * - HTML, CSS, JavaScript
 * - Images, Audio, Fonts
 * - Dynamically loaded resources
 * - WebGL initialization
 * - Game engine startup
 *
 * Usage:
 *   node puppeteer_game_test.js <game_url>
 */

const puppeteer = require('puppeteer');
const fs = require('fs');

// Colors for terminal output
const colors = {
    reset: '\x1b[0m',
    bright: '\x1b[1m',
    red: '\x1b[31m',
    green: '\x1b[32m',
    yellow: '\x1b[33m',
    blue: '\x1b[34m',
    cyan: '\x1b[36m',
    magenta: '\x1b[35m',
};

function formatBytes(bytes) {
    if (bytes < 1024) return bytes + ' B';
    if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(2) + ' KB';
    return (bytes / 1024 / 1024).toFixed(2) + ' MB';
}

function formatTime(ms) {
    if (ms < 1000) return ms.toFixed(0) + ' ms';
    return (ms / 1000).toFixed(2) + ' s';
}

function getResourceType(url) {
    const ext = url.split('?')[0].split('.').pop().toLowerCase();

    if (['html', 'htm'].includes(ext)) return 'HTML';
    if (['css'].includes(ext)) return 'CSS';
    if (['js', 'mjs', 'ts'].includes(ext)) return 'JavaScript';
    if (['png', 'jpg', 'jpeg', 'gif', 'webp', 'svg', 'ico'].includes(ext)) return 'Image';
    if (['mp3', 'wav', 'ogg', 'm4a', 'aac'].includes(ext)) return 'Audio';
    if (['woff', 'woff2', 'ttf', 'otf', 'eot'].includes(ext)) return 'Font';
    if (['json'].includes(ext)) return 'JSON';
    if (['atlas', 'skel'].includes(ext)) return 'Spine';

    return 'Other';
}

async function testGameLoading(gameUrl, options = {}) {
    const {
        headless = true,
        timeout = 60000,
        waitForIdle = 5000,
        outputFile = null,
        verbose = true
    } = options;

    console.log(`${colors.cyan}════════════════════════════════════════════════════════${colors.reset}`);
    console.log(`${colors.cyan}  Puppeteer Game Loading Test${colors.reset}`);
    console.log(`${colors.cyan}════════════════════════════════════════════════════════${colors.reset}`);
    console.log('');
    console.log(`${colors.yellow}Game URL:${colors.reset}`);
    console.log(`  ${gameUrl}`);
    console.log('');
    console.log(`${colors.yellow}Options:${colors.reset}`);
    console.log(`  Headless: ${headless}`);
    console.log(`  Timeout: ${timeout}ms`);
    console.log(`  Wait for network idle: ${waitForIdle}ms`);
    console.log('');

    const requests = [];
    const responses = [];
    const failedRequests = [];
    let startTime = null;

    console.log(`${colors.cyan}Launching browser...${colors.reset}`);
    const browser = await puppeteer.launch({
        headless: headless ? 'new' : false,
        args: [
            '--no-sandbox',
            '--disable-setuid-sandbox',
            '--disable-dev-shm-usage',
            '--no-first-run',
            '--no-zygote',
            '--ignore-gpu-blacklist',
            '--enable-webgl',
            '--use-gl=angle',
            '--use-angle=swiftshader',
            '--enable-accelerated-2d-canvas',
            '--disable-blink-features=AutomationControlled'
        ],
        ignoreDefaultArgs: ['--enable-automation']
    });

    try {
        const page = await browser.newPage();

        // Set viewport
        await page.setViewport({
            width: 1280,
            height: 720,
            deviceScaleFactor: 1
        });

        // Disable cache
        await page.setCacheEnabled(false);

        // Listen to all network requests
        page.on('request', request => {
            requests.push({
                url: request.url(),
                method: request.method(),
                resourceType: request.resourceType(),
                time: Date.now()
            });
        });

        // Listen to all network responses
        page.on('response', async response => {
            const request = response.request();
            const timing = response.timing();

            try {
                const headers = response.headers();
                responses.push({
                    url: response.url(),
                    status: response.status(),
                    resourceType: getResourceType(response.url()),
                    size: parseInt(headers['content-length'] || 0),
                    time: Date.now(),
                    timing: timing,
                    mimeType: headers['content-type'] || 'unknown'
                });
            } catch (error) {
                // Some responses might fail to get headers
            }
        });

        // Listen to failed requests
        page.on('requestfailed', request => {
            failedRequests.push({
                url: request.url(),
                failure: request.failure(),
                time: Date.now()
            });
        });

        // Listen to console messages from the page
        const webglErrors = [];
        if (verbose) {
            page.on('console', msg => {
                const type = msg.type();
                const text = msg.text();
                if (type === 'error') {
                    // Track WebGL errors but don't spam the console
                    if (text.toLowerCase().includes('webgl') || text.includes('JSHandle@error')) {
                        webglErrors.push(text);
                        if (webglErrors.length === 1) {
                            console.log(`${colors.yellow}[Note]${colors.reset} WebGL errors detected (common in headless mode, won't affect resource loading)`);
                        }
                    } else {
                        console.log(`${colors.red}[Browser Console Error]${colors.reset} ${text}`);
                    }
                }
            });
        }

        // Listen to page errors
        page.on('pageerror', error => {
            const msg = error.message;
            // Ignore WebGL-related errors
            if (!msg.includes('getParameter') && !msg.includes('webgl')) {
                console.log(`${colors.red}[Page Error]${colors.reset} ${msg}`);
            }
        });

        console.log(`${colors.cyan}Navigating to game...${colors.reset}`);
        console.log('');

        startTime = Date.now();

        // Navigate to the page
        await page.goto(gameUrl, {
            waitUntil: 'networkidle2',
            timeout: timeout
        });

        const navigationTime = Date.now();
        console.log(`${colors.green}✓${colors.reset} Page navigation complete: ${formatTime(navigationTime - startTime)}`);
        console.log('');

        // Try to click "CLICK TO PLAY" or similar buttons
        console.log(`${colors.cyan}Looking for game start button...${colors.reset}`);
        const beforeClickRequests = responses.length;

        try {
            // Wait a bit for the page to be ready
            await new Promise(resolve => setTimeout(resolve, 3000));

            // Try to find and click common game start buttons
            const clicked = await page.evaluate(() => {
                // Common button selectors and text patterns
                const patterns = [
                    'CLICK TO PLAY',
                    'START',
                    'PLAY',
                    '開始',
                    '播放',
                    'TAP TO START'
                ];

                // Try to find by text content
                const allElements = document.querySelectorAll('*');
                for (const el of allElements) {
                    const text = el.textContent?.trim().toUpperCase();
                    if (text && patterns.some(p => text.includes(p.toUpperCase()))) {
                        // Check if element is clickable
                        const style = window.getComputedStyle(el);
                        if (style.display !== 'none' && style.visibility !== 'hidden') {
                            el.click();
                            return true;
                        }
                    }
                }

                // Try to find canvas and click it (some games start on canvas click)
                const canvas = document.querySelector('canvas');
                if (canvas) {
                    canvas.click();
                    return true;
                }

                return false;
            });

            if (clicked) {
                console.log(`  ${colors.green}✓${colors.reset} Game start button clicked`);
                console.log(`  ${colors.yellow}Waiting for game to start and load additional resources...${colors.reset}`);

                // Wait for resources triggered by the click to start loading
                await new Promise(resolve => setTimeout(resolve, 5000));

                const afterClickRequests = responses.length;
                const newRequests = afterClickRequests - beforeClickRequests;
                console.log(`  ${colors.cyan}${newRequests} new resources loaded after clicking start${colors.reset}`);
                console.log('');
            } else {
                console.log(`  ${colors.yellow}⚠${colors.reset} No start button found (game may auto-start)`);
                console.log('');
            }
        } catch (error) {
            console.log(`  ${colors.yellow}⚠${colors.reset} Could not interact with page: ${error.message}`);
            console.log('');
        }

        // Wait for game to be ready - monitor until network settles and game UI is ready
        console.log(`${colors.cyan}Waiting for game to load and become ready...${colors.reset}`);

        let lastRequestTime = Date.now();
        let requestCount = responses.length;
        const maxWaitTime = Math.max(waitForIdle, 60000); // At least 60 seconds max
        const idleThreshold = 5000; // 5 seconds with no new requests (increased from 2s)
        const startWaitTime = Date.now();

        // Update last request time tracking
        const requestTimeTracker = setInterval(() => {
            if (responses.length > requestCount) {
                lastRequestTime = Date.now();
                requestCount = responses.length;
            }
        }, 100);

        while (Date.now() - startWaitTime < maxWaitTime) {
            const idleTime = Date.now() - lastRequestTime;
            const elapsed = Date.now() - startWaitTime;

            // Check if game is ready (network mostly idle)
            // Wait for at least 15 seconds AND network idle for 5 seconds
            if (elapsed >= 15000 && idleTime >= idleThreshold && responses.length > 20) {
                // Give extra time for any final lazy-loaded resources
                console.log('');
                console.log(`  ${colors.yellow}Network appears idle, waiting 5 more seconds to ensure all resources loaded...${colors.reset}`);
                await new Promise(resolve => setTimeout(resolve, 5000));

                // Check if any new resources arrived during the wait
                if (responses.length > requestCount) {
                    console.log(`  ${colors.yellow}New resources detected (${responses.length - requestCount}), continuing to monitor...${colors.reset}`);
                    lastRequestTime = Date.now();
                    requestCount = responses.length;
                    continue;
                }
                break;
            }

            // Progress indicator every 2 seconds
            if (Math.floor(elapsed / 2000) !== Math.floor((elapsed - 500) / 2000)) {
                process.stdout.write(`\r  ${formatTime(elapsed)} elapsed | ${responses.length} resources loaded | ${formatTime(idleTime)} since last request`);
            }

            await new Promise(resolve => setTimeout(resolve, 500));
        }

        clearInterval(requestTimeTracker);
        console.log('');
        console.log(`${colors.green}✓${colors.reset} Game loading complete`);

        const finalTime = Date.now();
        const totalTime = finalTime - startTime;

        console.log(`${colors.green}✓${colors.reset} All resources loaded`);
        console.log('');

        // Analyze the results
        console.log(`${colors.cyan}════════════════════════════════════════════════════════${colors.reset}`);
        console.log(`${colors.cyan}  Results Summary${colors.reset}`);
        console.log(`${colors.cyan}════════════════════════════════════════════════════════${colors.reset}`);
        console.log('');

        // Group by resource type
        const byType = {};
        let totalSize = 0;

        responses.forEach(resp => {
            const type = resp.resourceType;
            if (!byType[type]) {
                byType[type] = {
                    count: 0,
                    size: 0,
                    urls: []
                };
            }
            byType[type].count++;
            byType[type].size += resp.size;
            byType[type].urls.push({
                url: resp.url,
                size: resp.size,
                status: resp.status
            });
            totalSize += resp.size;
        });

        // Display by resource type
        console.log(`${colors.yellow}Resources by Type:${colors.reset}`);
        console.log('');

        const typeOrder = ['HTML', 'CSS', 'JavaScript', 'Image', 'Audio', 'Font', 'JSON', 'Spine', 'Other'];
        typeOrder.forEach(type => {
            if (byType[type]) {
                const data = byType[type];
                console.log(`  ${colors.green}✓${colors.reset} ${type.padEnd(12)} ${String(data.count).padStart(3)} files | ${formatBytes(data.size).padStart(12)}`);
            }
        });

        console.log('');
        console.log(`  ${colors.cyan}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${colors.reset}`);
        console.log(`  ${colors.bright}Total:${colors.reset}       ${String(responses.length).padStart(3)} files | ${formatBytes(totalSize).padStart(12)}`);
        console.log('');

        // Timeline
        console.log(`${colors.yellow}Loading Timeline:${colors.reset}`);
        console.log('');
        console.log(`  Navigation to networkidle2:  ${formatTime(navigationTime - startTime)}`);
        console.log(`  Additional wait time:        ${formatTime(waitForIdle)}`);
        console.log(`  ${colors.cyan}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${colors.reset}`);
        console.log(`  ${colors.bright}Total loading time:${colors.reset}          ${colors.yellow}${formatTime(totalTime)}${colors.reset}`);
        console.log('');

        // Failed requests
        if (failedRequests.length > 0) {
            console.log(`${colors.red}Failed Requests: ${failedRequests.length}${colors.reset}`);
            console.log('');
            failedRequests.forEach(req => {
                console.log(`  ${colors.red}✗${colors.reset} ${req.url}`);
                console.log(`    Reason: ${req.failure.errorText}`);
            });
            console.log('');
        }

        // Top 10 largest files
        console.log(`${colors.yellow}Top 10 Largest Files:${colors.reset}`);
        console.log('');

        const sortedResponses = [...responses].sort((a, b) => b.size - a.size);
        sortedResponses.slice(0, 10).forEach((resp, index) => {
            const filename = resp.url.split('/').pop().split('?')[0] || resp.url;
            const displayName = filename.length > 50 ? filename.substring(0, 47) + '...' : filename;
            console.log(`  ${String(index + 1).padStart(2)}. ${displayName.padEnd(50)} ${formatBytes(resp.size).padStart(12)} (${resp.resourceType})`);
        });
        console.log('');

        // Save detailed report if requested
        if (outputFile) {
            const report = {
                url: gameUrl,
                timestamp: new Date().toISOString(),
                totalTime: totalTime,
                navigationTime: navigationTime - startTime,
                totalRequests: responses.length,
                totalSize: totalSize,
                failedRequests: failedRequests.length,
                byType: byType,
                allResponses: responses,
                failedRequests: failedRequests
            };

            fs.writeFileSync(outputFile, JSON.stringify(report, null, 2));
            console.log(`${colors.green}✓${colors.reset} Detailed report saved to: ${outputFile}`);
            console.log('');
        }

        // Final summary box
        console.log(`${colors.cyan}════════════════════════════════════════════════════════${colors.reset}`);
        console.log(`${colors.green}✓ Test Complete${colors.reset}`);
        console.log(`${colors.cyan}════════════════════════════════════════════════════════${colors.reset}`);
        console.log('');
        console.log(`  Total Files:    ${responses.length}`);
        console.log(`  Total Size:     ${formatBytes(totalSize)}`);
        console.log(`  Loading Time:   ${colors.yellow}${formatTime(totalTime)}${colors.reset}`);
        console.log(`  Failed:         ${failedRequests.length > 0 ? colors.red : colors.green}${failedRequests.length}${colors.reset}`);
        console.log('');

        return {
            success: true,
            totalTime: totalTime,
            totalRequests: responses.length,
            totalSize: totalSize,
            failedRequests: failedRequests.length,
            byType: byType
        };

    } catch (error) {
        console.error(`${colors.red}Error during test:${colors.reset}`, error.message);
        return {
            success: false,
            error: error.message
        };
    } finally {
        await browser.close();
    }
}

// Main execution
if (require.main === module) {
    const args = process.argv.slice(2);

    if (args.length === 0) {
        console.log('Usage: node puppeteer_game_test.js <game_url> [options]');
        console.log('');
        console.log('Options:');
        console.log('  --headless=false      Show browser window');
        console.log('  --timeout=60000       Maximum wait time (ms)');
        console.log('  --wait=5000           Wait time after networkidle2 (ms)');
        console.log('  --output=report.json  Save detailed report to file');
        console.log('');
        console.log('Example:');
        console.log('  node puppeteer_game_test.js "https://example.com/game?token=..." --wait=10000 --output=report.json');
        process.exit(1);
    }

    const gameUrl = args[0];
    const options = {
        headless: true,
        timeout: 60000,
        waitForIdle: 5000,
        outputFile: null,
        verbose: true
    };

    // Parse options
    args.slice(1).forEach(arg => {
        if (arg.startsWith('--headless=')) {
            options.headless = arg.split('=')[1] !== 'false';
        } else if (arg.startsWith('--timeout=')) {
            options.timeout = parseInt(arg.split('=')[1]);
        } else if (arg.startsWith('--wait=')) {
            options.waitForIdle = parseInt(arg.split('=')[1]);
        } else if (arg.startsWith('--output=')) {
            options.outputFile = arg.split('=')[1];
        }
    });

    testGameLoading(gameUrl, options)
        .then(result => {
            process.exit(result.success ? 0 : 1);
        })
        .catch(error => {
            console.error('Fatal error:', error);
            process.exit(1);
        });
}

module.exports = { testGameLoading };
