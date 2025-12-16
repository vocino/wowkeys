// Tooltip functionality for ability keys

document.addEventListener('DOMContentLoaded', function() {
  const keys = document.querySelectorAll('.key.has-ability');
  
  keys.forEach(key => {
    const tooltip = key.querySelector('.tooltip');
    
    if (!tooltip) return;
    
    // Show tooltip on hover
    key.addEventListener('mouseenter', function(e) {
      tooltip.style.display = 'block';
      positionTooltip(tooltip, key);
    });
    
    // Hide tooltip on mouse leave
    key.addEventListener('mouseleave', function() {
      tooltip.style.display = 'none';
    });
    
    // Update position on mouse move for better positioning
    key.addEventListener('mousemove', function(e) {
      positionTooltip(tooltip, key);
    });
  });
});

function positionTooltip(tooltip, key) {
  const rect = key.getBoundingClientRect();
  const tooltipRect = tooltip.getBoundingClientRect();
  const viewportWidth = window.innerWidth;
  const viewportHeight = window.innerHeight;
  
  // Default: center above the key
  let left = rect.left + (rect.width / 2) - (tooltipRect.width / 2);
  let top = rect.top - tooltipRect.height - 10;
  
  // Adjust if tooltip would go off-screen to the right
  if (left + tooltipRect.width > viewportWidth - 10) {
    left = viewportWidth - tooltipRect.width - 10;
  }
  
  // Adjust if tooltip would go off-screen to the left
  if (left < 10) {
    left = 10;
  }
  
  // If tooltip would go off-screen at the top, show below instead
  if (top < 10) {
    top = rect.bottom + 10;
    tooltip.classList.add('tooltip-below');
  } else {
    tooltip.classList.remove('tooltip-below');
  }
  
  // Position relative to viewport
  tooltip.style.position = 'fixed';
  tooltip.style.left = left + 'px';
  tooltip.style.top = top + 'px';
  
  // Adjust arrow position if tooltip is below
  if (tooltip.classList.contains('tooltip-below')) {
    tooltip.style.setProperty('--arrow-top', 'auto');
    tooltip.style.setProperty('--arrow-bottom', '100%');
  } else {
    tooltip.style.setProperty('--arrow-top', '100%');
    tooltip.style.setProperty('--arrow-bottom', 'auto');
  }
}

