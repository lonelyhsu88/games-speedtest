#!/usr/bin/env node

/**
 * Puppeteer Game Loading Test (FIXED VERSION with ENHANCED CLICK STRATEGY)
 *
 * Key improvements:
 * 1. Accurate response size using CDP getResponseBody
 * 2. Fixed requestCount tracking logic
 * 3. Better error handling with counters
 * 4. Enhanced multi-strategy click detection for Canvas-based games
 * 5. Resource loading waterfall tracking
 *
 * Enhanced Click Strategy:
 * - Strategy 1: Multi-position canvas click (center, center-lower, lower-center, center-upper)
 * - Strategy 2: Multiple rapid clicks (3x at center-lower position)
 * - Strategy 3: HTML overlay buttons (rare cases)
 * - Each strategy validates success by monitoring new resource loading
 */

const puppeteer = require('puppeteer');
const fs = require('fs');

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
    console.log(`${colors.cyan}  Puppeteer Game Loading Test (FIXED)${colors.reset}`);
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

    const responses = [];
    const failedRequests = [];
    const skippedResponses = [];
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

        // Enable Chrome DevTools Protocol for accurate size tracking
        const client = await page.target().createCDPSession();
        await client.send('Network.enable');

        // Track requests using CDP for accurate size
        const requestIdMap = new Map();

        client.on('Network.requestWillBeSent', event => {
            requestIdMap.set(event.requestId, {
                url: event.request.url,
                method: event.request.method,
                startTime: event.timestamp * 1000,
                type: event.type
            });
        });

        client.on('Network.responseReceived', async event => {
            const request = requestIdMap.get(event.requestId);
            if (!request) return;

            try {
                // Get actual response body to calculate real size
                const responseBody = await client.send('Network.getResponseBody', {
                    requestId: event.requestId
                }).catch(() => null);

                let actualSize = 0;
                if (responseBody) {
                    actualSize = Buffer.byteLength(
                        responseBody.body,
                        responseBody.base64Encoded ? 'base64' : 'utf8'
                    );
                } else {
                    // Fallback to encodedDataLength from CDP
                    actualSize = event.response.encodedDataLength || 0;
                }

                responses.push({
                    url: event.response.url,
                    status: event.response.status,
                    resourceType: getResourceType(event.response.url),
                    size: actualSize,
                    encodedSize: event.response.encodedDataLength || 0,
                    time: Date.now(),
                    timing: event.response.timing,
                    mimeType: event.response.mimeType || 'unknown',
                    fromCache: event.response.fromDiskCache || event.response.fromServiceWorker || false
                });
            } catch (error) {
                skippedResponses.push({
                    url: event.response.url,
                    error: error.message
                });
            }
        });

        client.on('Network.loadingFailed', event => {
            const request = requestIdMap.get(event.requestId);
            failedRequests.push({
                url: request ? request.url : event.documentURL || 'unknown',
                requestId: event.requestId,
                error: event.errorText,
                type: event.type,
                canceled: event.canceled || false,
                blockedReason: event.blockedReason || null,
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
                    if (text.toLowerCase().includes('webgl') || text.includes('JSHandle@error')) {
                        webglErrors.push(text);
                        if (webglErrors.length === 1) {
                            console.log(`${colors.yellow}[Note]${colors.reset} WebGL errors detected (common in headless mode)`);
                        }
                    } else {
                        console.log(`${colors.red}[Browser Error]${colors.reset} ${text}`);
                    }
                }
            });
        }

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

        // Enhanced Click Strategy - Try multiple approaches
        console.log(`${colors.cyan}Looking for game start button (Enhanced Strategy)...${colors.reset}`);
        const beforeClickRequests = responses.length;

        try {
            // Wait for page to be ready
            await new Promise(resolve => setTimeout(resolve, 3000));

            // Strategy 1: Try multiple canvas positions with validation
            console.log(`  ${colors.cyan}Strategy 1: Multi-position canvas click${colors.reset}`);

            const positions = [
                { name: 'center', x: 0.5, y: 0.5 },
                { name: 'center-lower', x: 0.5, y: 0.6 },
                { name: 'lower-center', x: 0.5, y: 0.7 },
                { name: 'center-upper', x: 0.5, y: 0.4 },
            ];

            let clickSuccessful = false;
            let successInfo = null;

            for (const pos of positions) {
                const clicked = await page.evaluate(({ posX, posY }) => {
                    const canvas = document.querySelector('canvas');
                    if (!canvas) return { success: false, reason: 'No canvas found' };

                    const rect = canvas.getBoundingClientRect();
                    const x = rect.left + rect.width * posX;
                    const y = rect.top + rect.height * posY;

                    // Dispatch multiple event types for compatibility
                    const events = [
                        new MouseEvent('mousedown', { clientX: x, clientY: y, bubbles: true }),
                        new MouseEvent('mouseup', { clientX: x, clientY: y, bubbles: true }),
                        new MouseEvent('click', { clientX: x, clientY: y, bubbles: true }),
                        new PointerEvent('pointerdown', { clientX: x, clientY: y, bubbles: true }),
                        new PointerEvent('pointerup', { clientX: x, clientY: y, bubbles: true }),
                    ];

                    events.forEach(event => canvas.dispatchEvent(event));

                    return {
                        success: true,
                        position: { x: Math.round(x), y: Math.round(y) },
                        canvasSize: { width: rect.width, height: rect.height }
                    };
                }, { posX: pos.x, posY: pos.y });

                if (!clicked.success) {
                    console.log(`    ${colors.yellow}⚠${colors.reset} ${pos.name}: ${clicked.reason}`);
                    continue;
                }

                console.log(`    → ${pos.name} (${(pos.x * 100)}%, ${(pos.y * 100)}%) at pixel (${clicked.position.x}, ${clicked.position.y})`);

                // Wait and check if resources started loading
                await new Promise(resolve => setTimeout(resolve, 2000));

                const newResourceCount = responses.length - beforeClickRequests;

                if (newResourceCount > 5) {
                    console.log(`    ${colors.green}✓${colors.reset} Success! ${newResourceCount} new resources detected`);
                    clickSuccessful = true;
                    successInfo = { strategy: 'multi-position', position: pos.name, resources: newResourceCount };
                    break;
                } else {
                    console.log(`    ${colors.yellow}⚠${colors.reset} Only ${newResourceCount} new resources, trying next...`);
                }
            }

            // Strategy 2: Multiple rapid clicks if Strategy 1 failed
            if (!clickSuccessful) {
                console.log(`  ${colors.cyan}Strategy 2: Multiple rapid clicks${colors.reset}`);

                await page.evaluate(() => {
                    const canvas = document.querySelector('canvas');
                    if (!canvas) return;

                    const rect = canvas.getBoundingClientRect();
                    const x = rect.left + rect.width * 0.5;
                    const y = rect.top + rect.height * 0.6;

                    // Click 3 times rapidly
                    for (let i = 0; i < 3; i++) {
                        ['mousedown', 'mouseup', 'click', 'pointerdown', 'pointerup'].forEach(type => {
                            const event = type.startsWith('pointer')
                                ? new PointerEvent(type, { clientX: x, clientY: y, bubbles: true })
                                : new MouseEvent(type, { clientX: x, clientY: y, bubbles: true });
                            canvas.dispatchEvent(event);
                        });
                    }
                });

                console.log(`    → Triple-clicked at center-lower position`);

                await new Promise(resolve => setTimeout(resolve, 3000));

                const newResourceCount = responses.length - beforeClickRequests;

                if (newResourceCount > 5) {
                    console.log(`    ${colors.green}✓${colors.reset} Success! ${newResourceCount} new resources detected`);
                    clickSuccessful = true;
                    successInfo = { strategy: 'rapid-clicks', resources: newResourceCount };
                }
            }

            // Strategy 3: HTML overlay buttons (rare)
            if (!clickSuccessful) {
                console.log(`  ${colors.cyan}Strategy 3: HTML overlay buttons${colors.reset}`);

                const htmlClick = await page.evaluate(() => {
                    const patterns = ['CLICK TO PLAY', 'START', 'PLAY', '開始', 'TAP TO START'];

                    // Try buttons
                    const buttons = document.querySelectorAll('button, [role="button"], .button, .btn');
                    for (const btn of buttons) {
                        const text = btn.textContent?.trim().toUpperCase() || '';
                        if (patterns.some(p => text.includes(p))) {
                            const style = window.getComputedStyle(btn);
                            if (style.display !== 'none' && style.visibility !== 'hidden') {
                                btn.click();
                                return { success: true, type: 'button', text: btn.textContent };
                            }
                        }
                    }

                    // Try any clickable element
                    const allElements = document.querySelectorAll('div, span, a, img');
                    for (const el of allElements) {
                        const text = el.textContent?.trim().toUpperCase() || '';
                        const alt = el.getAttribute('alt')?.toUpperCase() || '';

                        if (patterns.some(p => text.includes(p) || alt.includes(p))) {
                            const style = window.getComputedStyle(el);
                            const rect = el.getBoundingClientRect();

                            if (style.display !== 'none' &&
                                style.visibility !== 'hidden' &&
                                style.opacity !== '0' &&
                                rect.width > 0 && rect.height > 0) {
                                el.click();
                                return { success: true, type: el.tagName.toLowerCase(), text: text || alt };
                            }
                        }
                    }

                    return { success: false };
                });

                if (htmlClick.success) {
                    console.log(`    ${colors.green}✓${colors.reset} Found HTML ${htmlClick.type}: "${htmlClick.text}"`);

                    await new Promise(resolve => setTimeout(resolve, 3000));

                    const newResourceCount = responses.length - beforeClickRequests;
                    if (newResourceCount > 0) {
                        clickSuccessful = true;
                        successInfo = { strategy: 'html-button', element: htmlClick.type, resources: newResourceCount };
                    }
                }
            }

            // Final assessment
            const totalNewResources = responses.length - beforeClickRequests;

            if (clickSuccessful && successInfo) {
                console.log('');
                console.log(`  ${colors.green}✓ Click successful using ${successInfo.strategy}${colors.reset}`);
                console.log(`  ${colors.cyan}${totalNewResources} new resources loaded after clicking${colors.reset}`);
                console.log('');
            } else if (totalNewResources > 0) {
                console.log('');
                console.log(`  ${colors.yellow}⚠ Uncertain: ${totalNewResources} resources loaded (game may auto-start)${colors.reset}`);
                console.log('');
            } else {
                console.log('');
                console.log(`  ${colors.yellow}⚠ No click response detected (game may not require click)${colors.reset}`);
                console.log('');
            }

        } catch (error) {
            console.log(`  ${colors.red}✗${colors.reset} Click error: ${error.message}`);
            console.log('');
        }

        // Wait for game to be ready - FIXED tracking logic
        console.log(`${colors.cyan}Waiting for game to fully load...${colors.reset}`);

        let lastRequestTime = Date.now();
        const maxWaitTime = Math.max(waitForIdle, 60000);
        const idleThreshold = 5000;
        const startWaitTime = Date.now();

        // Snapshot of count at start of idle detection
        let snapshotCount = responses.length;

        while (Date.now() - startWaitTime < maxWaitTime) {
            // Update last request time if new responses arrived
            if (responses.length > snapshotCount) {
                lastRequestTime = Date.now();
                snapshotCount = responses.length;
            }

            const idleTime = Date.now() - lastRequestTime;
            const elapsed = Date.now() - startWaitTime;

            // Check if ready (at least 15s elapsed AND 5s idle)
            if (elapsed >= 15000 && idleTime >= idleThreshold && responses.length > 20) {
                console.log('');
                console.log(`  ${colors.yellow}Network idle detected, verifying...${colors.reset}`);

                const beforeVerify = responses.length;
                await new Promise(resolve => setTimeout(resolve, 5000));
                const afterVerify = responses.length;

                if (afterVerify > beforeVerify) {
                    console.log(`  ${colors.yellow}${afterVerify - beforeVerify} more resources detected, continuing...${colors.reset}`);
                    snapshotCount = afterVerify;
                    lastRequestTime = Date.now();
                    continue;
                }

                console.log(`  ${colors.green}✓${colors.reset} Verified - no new resources`);
                break;
            }

            // Progress indicator
            if (Math.floor(elapsed / 2000) !== Math.floor((elapsed - 500) / 2000)) {
                process.stdout.write(`\r  ${formatTime(elapsed)} | ${responses.length} resources | ${formatTime(idleTime)} idle`);
            }

            await new Promise(resolve => setTimeout(resolve, 500));
        }

        console.log('');
        console.log(`${colors.green}✓${colors.reset} Game loading complete`);
        console.log('');

        const finalTime = Date.now();
        const totalTime = finalTime - startTime;

        // Analyze the results
        console.log(`${colors.cyan}════════════════════════════════════════════════════════${colors.reset}`);
        console.log(`${colors.cyan}  Results Summary${colors.reset}`);
        console.log(`${colors.cyan}════════════════════════════════════════════════════════${colors.reset}`);
        console.log('');

        // Group by resource type
        const byType = {};
        let totalSize = 0;
        let totalEncodedSize = 0;
        let fromCacheCount = 0;

        responses.forEach(resp => {
            const type = resp.resourceType;
            if (!byType[type]) {
                byType[type] = {
                    count: 0,
                    size: 0,
                    encodedSize: 0,
                    urls: []
                };
            }
            byType[type].count++;
            byType[type].size += resp.size;
            byType[type].encodedSize += resp.encodedSize;
            byType[type].urls.push({
                url: resp.url,
                size: resp.size,
                status: resp.status
            });
            totalSize += resp.size;
            totalEncodedSize += resp.encodedSize;
            if (resp.fromCache) fromCacheCount++;
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
        console.log(`  ${colors.cyan}Transferred:${colors.reset} ${formatBytes(totalEncodedSize).padStart(12)} (after compression)`);
        console.log(`  ${colors.cyan}From cache:${colors.reset}  ${fromCacheCount} resources`);
        console.log('');

        // Timeline
        console.log(`${colors.yellow}Loading Timeline:${colors.reset}`);
        console.log('');
        console.log(`  Navigation to networkidle2:  ${formatTime(navigationTime - startTime)}`);
        console.log(`  Additional loading time:     ${formatTime(finalTime - navigationTime)}`);
        console.log(`  ${colors.cyan}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${colors.reset}`);
        console.log(`  ${colors.bright}Total loading time:${colors.reset}          ${colors.yellow}${formatTime(totalTime)}${colors.reset}`);
        console.log('');

        // Failed requests
        if (failedRequests.length > 0) {
            console.log(`${colors.red}Failed Requests: ${failedRequests.length}${colors.reset}`);
            console.log('');
            failedRequests.slice(0, 10).forEach(req => {
                console.log(`  ${colors.red}✗${colors.reset} ${req.url}`);
                console.log(`    Error: ${req.error}`);
            });
            if (failedRequests.length > 10) {
                console.log(`  ... and ${failedRequests.length - 10} more`);
            }
            console.log('');
        }

        // Skipped responses (for debugging)
        if (skippedResponses.length > 0 && verbose) {
            console.log(`${colors.yellow}Skipped Responses: ${skippedResponses.length}${colors.reset}`);
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
                totalEncodedSize: totalEncodedSize,
                fromCacheCount: fromCacheCount,
                failedRequests: failedRequests.length,
                skippedResponses: skippedResponses.length,
                byType: byType,
                allResponses: responses.map(r => ({
                    url: r.url,
                    status: r.status,
                    type: r.resourceType,
                    size: r.size,
                    encodedSize: r.encodedSize,
                    fromCache: r.fromCache
                })),
                failedRequests: failedRequests
            };

            fs.writeFileSync(outputFile, JSON.stringify(report, null, 2));
            console.log(`${colors.green}✓${colors.reset} Detailed report saved to: ${outputFile}`);
            console.log('');
        }

        // Final summary
        console.log(`${colors.cyan}════════════════════════════════════════════════════════${colors.reset}`);
        console.log(`${colors.green}✓ Test Complete${colors.reset}`);
        console.log(`${colors.cyan}════════════════════════════════════════════════════════${colors.reset}`);
        console.log('');
        console.log(`  Total Resources:  ${responses.length}`);
        console.log(`  Total Size:       ${formatBytes(totalSize)}`);
        console.log(`  Transferred:      ${formatBytes(totalEncodedSize)}`);
        console.log(`  Loading Time:     ${colors.yellow}${formatTime(totalTime)}${colors.reset}`);
        console.log(`  Failed:           ${failedRequests.length > 0 ? colors.red : colors.green}${failedRequests.length}${colors.reset}`);
        console.log('');

        return {
            success: true,
            totalTime: totalTime,
            totalRequests: responses.length,
            totalSize: totalSize,
            totalEncodedSize: totalEncodedSize,
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
        console.log('Usage: node puppeteer_game_test_fixed.js <game_url> [options]');
        console.log('');
        console.log('Options:');
        console.log('  --headless=false      Show browser window');
        console.log('  --timeout=60000       Maximum wait time (ms)');
        console.log('  --wait=5000           Wait time after networkidle2 (ms)');
        console.log('  --output=report.json  Save detailed report to file');
        console.log('');
        console.log('Example:');
        console.log('  node puppeteer_game_test_fixed.js "https://example.com/game?token=..." --output=report.json');
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
