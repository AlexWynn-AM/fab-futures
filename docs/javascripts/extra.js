// Add toggle buttons to show/hide code cells
function initCodeToggles() {
  // Find all code cells
  const allCodeCells = document.querySelectorAll('.jp-Cell.jp-CodeCell');

  allCodeCells.forEach(function(cell) {
    // Skip if already processed or if it's nested inside another code cell
    if (cell.classList.contains('has-toggle')) return;
    if (cell.parentElement.closest('.jp-Cell.jp-CodeCell')) return;

    const inputWrapper = cell.querySelector('.jp-Cell-inputWrapper');
    if (!inputWrapper) return;

    // Mark as processed
    cell.classList.add('has-toggle');

    // Hide input by default
    inputWrapper.style.display = 'none';

    // Create toggle button
    const toggle = document.createElement('button');
    toggle.className = 'code-toggle';
    toggle.textContent = 'Show code';

    toggle.addEventListener('click', function() {
      const isHidden = inputWrapper.style.display === 'none';
      inputWrapper.style.display = isHidden ? 'block' : 'none';
      toggle.textContent = isHidden ? 'Hide code' : 'Show code';
    });

    // Insert button at the start of the cell
    cell.insertBefore(toggle, cell.firstChild);
  });
}

// Run on load and after short delay for dynamic content
document.addEventListener('DOMContentLoaded', function() {
  initCodeToggles();
  setTimeout(initCodeToggles, 100);
});
