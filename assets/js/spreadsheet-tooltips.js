// Dynamic tooltip positioning for spreadsheet abilities and keybinds
// Positions tooltip above or below based on available space

document.addEventListener('DOMContentLoaded', function() {
  // Handle ability tooltips
  const abilityDisplays = document.querySelectorAll('.ability-display[data-tooltip]');
  
  abilityDisplays.forEach(function(display) {
    const tooltip = display.querySelector('.ability-tooltip');
    if (!tooltip) return;
    
    display.addEventListener('mouseenter', function() {
      positionTooltip(display, tooltip);
    });
    
    display.addEventListener('mouseleave', function() {
      tooltip.style.display = 'none';
      tooltip.style.opacity = '0';
      tooltip.style.visibility = 'hidden';
    });
    
    // Reposition on scroll or resize
    window.addEventListener('scroll', function() {
      if (tooltip.style.display === 'block' && tooltip.style.opacity === '1') {
        positionTooltip(display, tooltip);
      }
    }, true);
    
    window.addEventListener('resize', function() {
      if (tooltip.style.display === 'block' && tooltip.style.opacity === '1') {
        positionTooltip(display, tooltip);
      }
    });
  });
  
  // Handle keybind tooltips
  const keybindTriggers = document.querySelectorAll('.keybind-tooltip-trigger[data-keybind-tooltip]');
  
  keybindTriggers.forEach(function(trigger) {
    const tooltip = trigger.querySelector('.keybind-tooltip');
    if (!tooltip) return;
    
    trigger.addEventListener('mouseenter', function() {
      positionKeybindTooltip(trigger, tooltip);
    });
    
    trigger.addEventListener('mouseleave', function() {
      tooltip.style.display = 'none';
      tooltip.style.opacity = '0';
      tooltip.style.visibility = 'hidden';
    });
    
    // Reposition on scroll or resize
    window.addEventListener('scroll', function() {
      if (tooltip.style.display === 'block' && tooltip.style.opacity === '1') {
        positionKeybindTooltip(trigger, tooltip);
      }
    }, true);
    
    window.addEventListener('resize', function() {
      if (tooltip.style.display === 'block' && tooltip.style.opacity === '1') {
        positionKeybindTooltip(trigger, tooltip);
      }
    });
  });
});

function positionTooltip(display, tooltip) {
  const displayRect = display.getBoundingClientRect();
  const tooltipRect = tooltip.getBoundingClientRect();
  const viewportHeight = window.innerHeight;
  const viewportWidth = window.innerWidth;
  
  // Temporarily show tooltip to measure it
  tooltip.style.display = 'block';
  tooltip.style.visibility = 'hidden';
  tooltip.style.opacity = '0';
  
  const tooltipHeight = tooltip.offsetHeight;
  const tooltipWidth = tooltip.offsetWidth;
  
  // Calculate space above and below
  const spaceAbove = displayRect.top;
  const spaceBelow = viewportHeight - displayRect.bottom;
  
  // Determine if tooltip should go above or below
  const showAbove = spaceAbove >= tooltipHeight || spaceBelow < spaceAbove;
  
  // Reset positioning
  tooltip.style.top = '';
  tooltip.style.bottom = '';
  tooltip.style.left = '';
  tooltip.style.marginTop = '';
  tooltip.style.marginBottom = '';
  tooltip.classList.remove('tooltip-above', 'tooltip-below');
  
  // Calculate horizontal position (center on display)
  let left = displayRect.left + (displayRect.width / 2) - (tooltipWidth / 2);
  
  // Adjust if tooltip would go off-screen to the right
  if (left + tooltipWidth > viewportWidth - 10) {
    left = viewportWidth - tooltipWidth - 10;
  }
  
  // Adjust if tooltip would go off-screen to the left
  if (left < 10) {
    left = 10;
  }
  
  // Position tooltip
  tooltip.style.position = 'fixed';
  tooltip.style.left = left + 'px';
  
  if (showAbove) {
    // Position above
    tooltip.style.bottom = (viewportHeight - displayRect.top + 8) + 'px';
    tooltip.style.top = 'auto';
    tooltip.classList.add('tooltip-above');
  } else {
    // Position below
    tooltip.style.top = (displayRect.bottom + 8) + 'px';
    tooltip.style.bottom = 'auto';
    tooltip.classList.add('tooltip-below');
  }
  
  // Show tooltip
  tooltip.style.visibility = 'visible';
  tooltip.style.opacity = '1';
}

function positionKeybindTooltip(display, tooltip) {
  const displayRect = display.getBoundingClientRect();
  const viewportHeight = window.innerHeight;
  const viewportWidth = window.innerWidth;
  
  // Temporarily show tooltip to measure it
  tooltip.style.display = 'block';
  tooltip.style.visibility = 'hidden';
  tooltip.style.opacity = '0';
  
  const tooltipHeight = tooltip.offsetHeight;
  const tooltipWidth = tooltip.offsetWidth;
  
  // Reset positioning
  tooltip.style.top = '';
  tooltip.style.bottom = '';
  tooltip.style.left = '';
  tooltip.style.marginTop = '';
  tooltip.style.marginBottom = '';
  tooltip.classList.remove('tooltip-above', 'tooltip-below');
  
  // For keybind cells on the left, position tooltip to the right of the cell
  let left = displayRect.right + 8;
  
  // If tooltip would go off-screen to the right, position it to the left of the cell instead
  if (left + tooltipWidth > viewportWidth - 10) {
    left = displayRect.left - tooltipWidth - 8;
    // If still off-screen, center it on the cell
    if (left < 10) {
      left = displayRect.left + (displayRect.width / 2) - (tooltipWidth / 2);
    }
  }
  
  // Ensure tooltip doesn't go off-screen
  if (left < 10) {
    left = 10;
  }
  if (left + tooltipWidth > viewportWidth - 10) {
    left = viewportWidth - tooltipWidth - 10;
  }
  
  // Vertically center the tooltip with the key cell
  const cellCenterY = displayRect.top + (displayRect.height / 2);
  let top = cellCenterY - (tooltipHeight / 2);
  
  // Adjust if tooltip would go off-screen at top
  if (top < 10) {
    top = 10;
  }
  
  // Adjust if tooltip would go off-screen at bottom
  if (top + tooltipHeight > viewportHeight - 10) {
    top = viewportHeight - tooltipHeight - 10;
  }
  
  // Position tooltip
  tooltip.style.position = 'fixed';
  tooltip.style.left = left + 'px';
  tooltip.style.top = top + 'px';
  tooltip.style.bottom = 'auto';
  
  // Show tooltip
  tooltip.style.visibility = 'visible';
  tooltip.style.opacity = '1';
}

