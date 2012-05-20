/**
 * Eric J. Duran
 *
 * Simple table username filter for our table.
 */
$(document).ready(function() {
  var $filter = $("#filter");
  $filter.on("keyup", function (e) {
    // Need to delay the call, as it was happening too many times when typing.
    setTimeout(function(){
      var needle = $filter.val().toLowerCase();
      // TODO: Add an id to the table, incase we add multiple tables as some point.
      $('table tbody tr').each(function(i, e) {
        // Lets only do the 1st td, since the orthers are pointless
        var haystack = $('td:first', $(this)).html().toLowerCase();
        if (haystack.indexOf(needle) == -1) {
          $(this).hide();
        }
        else {
          $(this).show();
        }
      });
    }, 500);
  });
});
