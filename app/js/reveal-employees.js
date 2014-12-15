$(function() {
  'use strict';
  $('table.companies tr td .toggle').click(function() {
    $(this).parent().find('.employees').toggle();
  });
});