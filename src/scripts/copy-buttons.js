// Shared clipboard behavior for any [data-copy-text] button.
// Copies the attribute's value, flashes "[copied]", then restores the label.
// Falls back to a prompt when the Clipboard API is unavailable (http, old Safari).

const COPIED_LABEL = '[copied]';
const RESET_MS = 1500;

document.addEventListener('DOMContentLoaded', function () {
  const buttons = document.querySelectorAll('[data-copy-text]');

  buttons.forEach(function (button) {
    const text = button.dataset.copyText ?? '';
    const originalLabel = button.textContent;
    const originalAriaLabel = button.getAttribute('aria-label');
    let resetTimer = null;

    button.addEventListener('click', async function () {
      let copied = true;

      try {
        await navigator.clipboard.writeText(text);
      } catch {
        copied = false;
        window.prompt('Copy this import string:', text);
      }

      if (!copied) return;

      button.textContent = COPIED_LABEL;
      button.classList.add('is-copied');
      if (originalAriaLabel !== null) {
        button.setAttribute('aria-label', 'Copied to clipboard');
      }

      clearTimeout(resetTimer);
      resetTimer = setTimeout(function () {
        button.textContent = originalLabel;
        button.classList.remove('is-copied');
        if (originalAriaLabel !== null) {
          button.setAttribute('aria-label', originalAriaLabel);
        }
      }, RESET_MS);
    });
  });
});
