/**
 * Enhanced Click Strategy for Canvas-based Games
 *
 * Handles "CLICK TO PLAY" buttons rendered on Canvas (not in DOM)
 * Tries multiple positions and validates if click was successful
 */

/**
 * Smart Canvas Click Strategy
 *
 * @param {Page} page - Puppeteer page object
 * @param {Array} responses - Response tracking array
 * @returns {Object} Click result with success status
 */
async function smartCanvasClick(page, responses) {
    const beforeClickCount = responses.length;

    console.log('Attempting smart canvas click strategy...');

    // Strategy 1: Try common button positions
    const positions = [
        { name: 'center', x: 0.5, y: 0.5 },          // Standard center
        { name: 'center-lower', x: 0.5, y: 0.6 },    // Most common for games
        { name: 'lower-center', x: 0.5, y: 0.7 },    // Even lower
        { name: 'center-upper', x: 0.5, y: 0.4 },    // Upper center
    ];

    for (const pos of positions) {
        console.log(`  Trying position: ${pos.name} (${(pos.x * 100)}%, ${(pos.y * 100)}%)`);

        const clicked = await page.evaluate(({ posX, posY }) => {
            const canvas = document.querySelector('canvas');
            if (!canvas) return { success: false, reason: 'No canvas found' };

            const rect = canvas.getBoundingClientRect();
            const x = rect.left + rect.width * posX;
            const y = rect.top + rect.height * posY;

            // Try both click and mousedown/mouseup
            const clickEvent = new MouseEvent('click', {
                view: window,
                bubbles: true,
                cancelable: true,
                clientX: x,
                clientY: y
            });

            const mousedownEvent = new MouseEvent('mousedown', {
                view: window,
                bubbles: true,
                cancelable: true,
                clientX: x,
                clientY: y
            });

            const mouseupEvent = new MouseEvent('mouseup', {
                view: window,
                bubbles: true,
                cancelable: true,
                clientX: x,
                clientY: y
            });

            // Dispatch all events
            canvas.dispatchEvent(mousedownEvent);
            canvas.dispatchEvent(mouseupEvent);
            canvas.dispatchEvent(clickEvent);

            // Also try pointerdown/pointerup for Pixi.js
            const pointerdownEvent = new PointerEvent('pointerdown', {
                view: window,
                bubbles: true,
                cancelable: true,
                clientX: x,
                clientY: y
            });

            const pointerupEvent = new PointerEvent('pointerup', {
                view: window,
                bubbles: true,
                cancelable: true,
                clientX: x,
                clientY: y
            });

            canvas.dispatchEvent(pointerdownEvent);
            canvas.dispatchEvent(pointerupEvent);

            return {
                success: true,
                position: { x: Math.round(x), y: Math.round(y) },
                canvasSize: { width: rect.width, height: rect.height }
            };
        }, { posX: pos.x, posY: pos.y });

        if (!clicked.success) {
            console.log(`  ✗ Failed: ${clicked.reason}`);
            continue;
        }

        console.log(`  → Clicked at pixel (${clicked.position.x}, ${clicked.position.y})`);

        // Wait and check if new resources started loading
        await new Promise(resolve => setTimeout(resolve, 2000));

        const newResourceCount = responses.length - beforeClickCount;

        if (newResourceCount > 3) {
            console.log(`  ✓ Success! ${newResourceCount} new resources detected`);
            return {
                success: true,
                position: pos.name,
                newResources: newResourceCount,
                clickLocation: clicked.position
            };
        } else {
            console.log(`  ⚠ Only ${newResourceCount} new resources, trying next position...`);
        }
    }

    // Strategy 2: If positions didn't work, try multiple rapid clicks on center
    console.log('  Trying multiple rapid clicks strategy...');

    const multiClickResult = await page.evaluate(() => {
        const canvas = document.querySelector('canvas');
        if (!canvas) return { success: false };

        const rect = canvas.getBoundingClientRect();
        const x = rect.left + rect.width * 0.5;
        const y = rect.top + rect.height * 0.6; // Slightly below center

        // Click 3 times rapidly
        for (let i = 0; i < 3; i++) {
            const events = ['mousedown', 'mouseup', 'click', 'pointerdown', 'pointerup'];
            events.forEach(eventType => {
                const event = eventType.startsWith('pointer')
                    ? new PointerEvent(eventType, { clientX: x, clientY: y, bubbles: true })
                    : new MouseEvent(eventType, { clientX: x, clientY: y, bubbles: true });
                canvas.dispatchEvent(event);
            });
        }

        return {
            success: true,
            clicks: 3,
            position: { x: Math.round(x), y: Math.round(y) }
        };
    });

    if (multiClickResult.success) {
        console.log(`  → Triple-clicked at (${multiClickResult.position.x}, ${multiClickResult.position.y})`);

        await new Promise(resolve => setTimeout(resolve, 3000));

        const newResourceCount = responses.length - beforeClickCount;

        if (newResourceCount > 3) {
            console.log(`  ✓ Success! ${newResourceCount} new resources detected`);
            return {
                success: true,
                strategy: 'multiple-clicks',
                newResources: newResourceCount
            };
        }
    }

    // Strategy 3: Try HTML overlay buttons as last resort
    console.log('  Trying HTML overlay buttons...');

    const htmlButtonClick = await page.evaluate(() => {
        const patterns = ['CLICK TO PLAY', 'START', 'PLAY', 'TAP TO START', 'CLICK TO START'];

        // Try buttons first
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

        // Try any clickable element with matching text
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

    if (htmlButtonClick.success) {
        console.log(`  ✓ Found HTML ${htmlButtonClick.type}: "${htmlButtonClick.text}"`);

        await new Promise(resolve => setTimeout(resolve, 3000));

        const newResourceCount = responses.length - beforeClickCount;

        if (newResourceCount > 0) {
            console.log(`  ✓ Success! ${newResourceCount} new resources detected`);
            return {
                success: true,
                strategy: 'html-button',
                element: htmlButtonClick.type,
                newResources: newResourceCount
            };
        }
    }

    // If all strategies failed
    const totalNewResources = responses.length - beforeClickCount;

    if (totalNewResources > 0) {
        console.log(`  ⚠ Uncertain success: ${totalNewResources} resources loaded (may auto-start)`);
        return {
            success: 'uncertain',
            newResources: totalNewResources,
            note: 'Game may have auto-started without click'
        };
    }

    console.log('  ✗ All click strategies failed');
    return {
        success: false,
        newResources: 0,
        note: 'Game may not require click, or click detection failed'
    };
}

/**
 * Fallback: Just click canvas center once (current implementation)
 */
async function simpleCanvasClick(page) {
    return await page.evaluate(() => {
        const canvas = document.querySelector('canvas');
        if (!canvas) return { success: false };

        const rect = canvas.getBoundingClientRect();
        const x = rect.left + rect.width / 2;
        const y = rect.top + rect.height / 2;

        const event = new MouseEvent('click', {
            view: window,
            bubbles: true,
            cancelable: true,
            clientX: x,
            clientY: y
        });

        canvas.dispatchEvent(event);

        return { success: true, position: { x, y } };
    });
}

module.exports = {
    smartCanvasClick,
    simpleCanvasClick
};
