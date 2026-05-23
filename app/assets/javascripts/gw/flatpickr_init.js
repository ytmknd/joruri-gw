// Initialize flatpickr on inputs with data-flatpickr attribute
jQuery(function($) {
  // Register Japanese locale
  if (typeof flatpickr !== 'undefined' && flatpickr.l10ns && flatpickr.l10ns.ja) {
    flatpickr.localize(flatpickr.l10ns.ja);
  }

  $('[data-flatpickr]').each(function() {
    var mode = $(this).data('flatpickr');
    var minuteInterval = parseInt($(this).data('minute-interval') || 1, 10);
    var config = { allowInput: true };

    if (mode === 'datetime') {
      config.enableTime    = true;
      config.dateFormat    = 'Y-m-d H:i';
      config.minuteIncrement = minuteInterval;
    } else if (mode === 'time') {
      config.noCalendar    = true;
      config.enableTime    = true;
      config.dateFormat    = 'H:i';
      config.minuteIncrement = minuteInterval;
    } else {
      // date (default)
      config.dateFormat = 'Y-m-d';
    }

    flatpickr(this, config);
  });
});
