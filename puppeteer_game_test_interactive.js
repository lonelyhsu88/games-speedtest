#!/usr/bin/env node

/**
 * Puppeteer Interactive Game Loading Test
 *
 * This script simulates REAL gameplay including:
 * - Clicking start button
 * - Random clicks on canvas (simulating gameplay)
 * - Long wait time to capture all resources
 * - Continuous monitoring until network is truly idle
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
    if (ms < 60000) return (ms / 1000).toFixed(2) + ' s';
    return (ms / 60000).toFixed(2) + ' min';
}

async function testGameLoadingInteractive(gameUrl, options = {}) {
    const {
        headless = true,
        timeout = 240000,  // 4 minutes
        playTime = 180000,  // 3 minutes of gameplay
        outputFile = null,
    } = options;

    console.log(`${colors.cyan}════════════════════════════════════════════════════════${colors.reset}`);
    console.log(`${colors.cyan}  Puppeteer Interactive Game Test${colors.reset}`);
    console.log(`${colors.cyan}════════════════════════════════════════════════════════${colors.reset}`);
    console.log('');
    console.log(`${colors.yellow}Game URL:${colors.reset}`);
    console.log(`  ${gameUrl}`);
    console.log('');
    console.log(`${colors.yellow}Options:${colors.reset}`);
    console.log(`  Headless: ${headless}`);
    console.log(`  Play time: ${formatTime(playTime)}`);
    console.log('');

    const requests = [];
    const responses = [];
    const failedRequests = [];
    let startTime = null;
    let lastRequestTime = Date.now();

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
        ]
    });

    try {
        const page = await browser.newPage();
        await page.setViewport({ width: 1280, height: 720 });
        await page.setCacheEnabled(false);

        // Listen to network requests
        page.on('request', request => {
            lastRequestTime = Date.now();
            requests.push({
                url: request.url(),
                time: Date.now()
            });
        });

        page.on('response', async response => {
            try {
                const headers = response.headers();
                responses.push({
                    url: response.url(),
                    status: response.status(),
                    size: parseInt(headers['content-length'] || 0),
                    time: Date.now(),
                });
            } catch (error) {}
        });

        page.on('requestfailed', request => {
            failedRequests.push({
                url: request.url(),
                failure: request.failure(),
            });
        });

        console.log(`${colors.cyan}Navigating to game...${colors.reset}`);
        startTime = Date.now();

        await page.goto(gameUrl, {
            waitUntil: 'networkidle2',
            timeout: timeout
        });

        const navTime = Date.now();
        console.log(`${colors.green}✓${colors.reset} Initial load: ${formatTime(navTime - startTime)}`);
        console.log(`  Requests so far: ${responses.length}`);
        console.log('');

        // Click start button
        console.log(`${colors.cyan}Looking for start button...${colors.reset}`);
        await new Promise(resolve => setTimeout(resolve, 2000));

        const clicked = await page.evaluate(() => {
            const patterns = ['CLICK TO PLAY', 'START', 'PLAY', '開始', 'TAP TO START'];
            const allElements = document.querySelectorAll('*');
            for (const el of allElements) {
                const text = el.textContent?.trim().toUpperCase();
                if (text && patterns.some(p => text.includes(p))) {
                    const style = window.getComputedStyle(el);
                    if (style.display !== 'none' && style.visibility !== 'hidden') {
                        el.click();
                        return true;
                    }
                }
            }
            const canvas = document.querySelector('canvas');
            if (canvas) {
                canvas.click();
                return true;
            }
            return false;
        });

        if (clicked) {
            console.log(`${colors.green}✓${colors.reset} Start button clicked`);
        }

        await new Promise(resolve => setTimeout(resolve, 3000));
        console.log(`  Requests after click: ${responses.length}`);
        console.log('');

        // Simulate gameplay
        console.log(`${colors.cyan}Simulating gameplay for ${formatTime(playTime)}...${colors.reset}`);
        console.log(`${colors.yellow}(Random clicks to trigger game events)${colors.reset}`);
        console.log('');

        const endTime = Date.now() + playTime;
        let clickCount = 0;

        while (Date.now() < endTime) {
            // Random click on canvas to simulate gameplay
            try {
                await page.evaluate(() => {
                    const canvas = document.querySelector('canvas');
                    if (canvas) {
                        const rect = canvas.getBoundingClientRect();
                        const x = rect.left + Math.random() * rect.width;
                        const y = rect.top + Math.random() * rect.height;

                        const event = new MouseEvent('click', {
                            view: window,
                            bubbles: true,
                            cancelable: true,
                            clientX: x,
                            clientY: y
                        });
                        canvas.dispatchEvent(event);
                    }
                });
                clickCount++;
            } catch (error) {}

            // Progress update every 30 seconds
            const remaining = endTime - Date.now();
            if (clickCount % 10 === 0) {
                console.log(`  ${formatTime(playTime - remaining)} elapsed | ${responses.length} requests | ${clickCount} clicks`);
            }

            // Wait between clicks
            await new Promise(resolve => setTimeout(resolve, 2000 + Math.random() * 3000));
        }

        console.log('');
        console.log(`${colors.green}✓${colors.reset} Gameplay simulation complete`);
        console.log(`  Total clicks: ${clickCount}`);
        console.log(`  Total requests: ${responses.length}`);
        console.log('');

        // Wait for final network idle
        console.log(`${colors.cyan}Waiting for final network idle...${colors.reset}`);
        const maxWait = 30000;  // Max 30 seconds
        const idleThreshold = 5000;  // 5 seconds with no requests
        const waitStart = Date.now();

        while (Date.now() - lastRequestTime < idleThreshold &&
               Date.now() - waitStart < maxWait) {
            await new Promise(resolve => setTimeout(resolve, 1000));
            process.stdout.write(`\r  Waiting... (${Math.floor((Date.now() - lastRequestTime) / 1000)}s since last request)`);
        }
        console.log('');
        console.log(`${colors.green}✓${colors.reset} Network idle reached`);
        console.log('');

        const finalTime = Date.now();
        const totalTime = finalTime - startTime;

        // Calculate statistics
        let totalSize = 0;
        const byType = {};

        responses.forEach(resp => {
            const url = resp.url;
            let type = 'Other';

            if (url.match(/\.(png|jpg|jpeg|gif|webp|svg)(\?|$)/i)) type = 'Image';
            else if (url.match(/\.(mp3|wav|ogg|m4a)(\?|$)/i)) type = 'Audio';
            else if (url.match(/\.(js|mjs)(\?|$)/i)) type = 'JavaScript';
            else if (url.match(/\.css(\?|$)/i)) type = 'CSS';
            else if (url.match(/\.json(\?|$)/i)) type = 'JSON';
            else if (url.match(/\.(html|htm)(\?|$)/i)) type = 'HTML';

            if (!byType[type]) {
                byType[type] = { count: 0, size: 0 };
            }
            byType[type].count++;
            byType[type].size += resp.size;
            totalSize += resp.size;
        });

        // Display results
        console.log(`${colors.cyan}════════════════════════════════════════════════════════${colors.reset}`);
        console.log(`${colors.cyan}  Final Results${colors.reset}`);
        console.log(`${colors.cyan}════════════════════════════════════════════════════════${colors.reset}`);
        console.log('');

        console.log(`${colors.yellow}Resources by Type:${colors.reset}`);
        console.log('');
        Object.entries(byType).sort((a, b) => b[1].size - a[1].size).forEach(([type, data]) => {
            console.log(`  ${colors.green}✓${colors.reset} ${type.padEnd(12)} ${String(data.count).padStart(3)} files | ${formatBytes(data.size).padStart(12)}`);
        });

        console.log('');
        console.log(`  ${colors.cyan}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${colors.reset}`);
        console.log(`  ${colors.bright}Total:${colors.reset}       ${String(responses.length).padStart(3)} files | ${formatBytes(totalSize).padStart(12)}`);
        console.log('');

        console.log(`${colors.yellow}Timeline:${colors.reset}`);
        console.log('');
        console.log(`  Initial load to networkidle2:  ${formatTime(navTime - startTime)}`);
        console.log(`  Gameplay simulation:           ${formatTime(playTime)}`);
        console.log(`  ${colors.cyan}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${colors.reset}`);
        console.log(`  ${colors.bright}Total test time:${colors.reset}               ${colors.yellow}${formatTime(totalTime)}${colors.reset}`);
        console.log('');

        if (failedRequests.length > 0) {
            console.log(`${colors.red}Failed Requests: ${failedRequests.length}${colors.reset}`);
            console.log('');
        }

        // Save detailed report
        if (outputFile) {
            const report = {
                url: gameUrl,
                timestamp: new Date().toISOString(),
                totalTime: totalTime,
                playTime: playTime,
                totalRequests: responses.length,
                totalSize: totalSize,
                clicks: clickCount,
                failedRequests: failedRequests.length,
                byType: byType,
                allResponses: responses,
            };
            fs.writeFileSync(outputFile, JSON.stringify(report, null, 2));
            console.log(`${colors.green}✓${colors.reset} Detailed report saved to: ${outputFile}`);
            console.log('');
        }

        console.log(`${colors.cyan}════════════════════════════════════════════════════════${colors.reset}`);
        console.log(`${colors.green}✓ Test Complete${colors.reset}`);
        console.log(`${colors.cyan}════════════════════════════════════════════════════════${colors.reset}`);
        console.log('');
        console.log(`  Total Requests:  ${responses.length}`);
        console.log(`  Total Size:      ${formatBytes(totalSize)}`);
        console.log(`  Test Duration:   ${colors.yellow}${formatTime(totalTime)}${colors.reset}`);
        console.log(`  Failed:          ${failedRequests.length > 0 ? colors.red : colors.green}${failedRequests.length}${colors.reset}`);
        console.log('');

        return {
            success: true,
            totalTime: totalTime,
            totalRequests: responses.length,
            totalSize: totalSize,
        };

    } catch (error) {
        console.error(`${colors.red}Error during test:${colors.reset}`, error.message);
        return { success: false, error: error.message };
    } finally {
        await browser.close();
    }
}

// Main execution
if (require.main === module) {
    const args = process.argv.slice(2);

    if (args.length === 0) {
        console.log('Usage: node puppeteer_game_test_interactive.js <game_url> [options]');
        console.log('');
        console.log('Options:');
        console.log('  --headless=false      Show browser window');
        console.log('  --playtime=180000     Gameplay simulation time (ms, default: 3 min)');
        console.log('  --output=report.json  Save detailed report');
        console.log('');
        console.log('Example:');
        console.log('  node puppeteer_game_test_interactive.js "https://..." --playtime=180000 --output=report.json');
        process.exit(1);
    }

    const gameUrl = args[0];
    const options = {
        headless: true,
        playTime: 180000,  // 3 minutes
        outputFile: null,
    };

    args.slice(1).forEach(arg => {
        if (arg.startsWith('--headless=')) {
            options.headless = arg.split('=')[1] !== 'false';
        } else if (arg.startsWith('--playtime=')) {
            options.playTime = parseInt(arg.split('=')[1]);
        } else if (arg.startsWith('--output=')) {
            options.outputFile = arg.split('=')[1];
        }
    });

    testGameLoadingInteractive(gameUrl, options)
        .then(result => {
            process.exit(result.success ? 0 : 1);
        })
        .catch(error => {
            console.error('Fatal error:', error);
            process.exit(1);
        });
}

module.exports = { testGameLoadingInteractive };
