var sys    = require('sys'),
    sqlite = require('sqlite'),
    git    = require('git');


// Set up a sqlite DB
var db = new sqlite.Database();

//

db.open("cores.db", function (error) {
  if (error) {
      console.log("Blah....");
      throw error;
  }
});

// Get the last rev

// Check the git directory exist

// 
