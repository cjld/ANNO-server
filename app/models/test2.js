mongoose = require("mongoose");
      var schema = new mongoose.Schema({
        name: { type: String, required: true },
        quest: { type: String, match: /Holy Grail/i, required: true },
        favoriteColor: { type: String, enum: ['Red', 'Blue'], required: true }
      });

      /* `mongoose.Document` is different in the browser than in NodeJS.
       * the constructor takes an initial state and a schema. You can
       * then modify the document and call `validate()` to make sure it
       * passes validation rules. */
      var doc = new mongoose.Document({}, schema);
      doc.validate(function(error) {
        assert.ok(error);
        assert.equal('Path `name` is required.', error.errors['name'].message);
        assert.equal('Path `quest` is required.', error.errors['quest'].message);
        assert.equal('Path `favoriteColor` is required.',
          error.errors['favoriteColor'].message);

        doc.name = 'Sir Lancelot of Camelot';
        doc.quest = 'To seek the holy grail';
        doc.favoriteColor = 'Blue';
        doc.validate(function(error) {
          assert.ifError(error);

          doc.name = 'Sir Galahad of Camelot';
          doc.quest = 'I seek the grail'; // Invalid, must contain 'holy grail'
          doc.favoriteColor = 'Yellow'; // Invalid, not 'Red' or 'Blue'
          doc.validate(function(error) {
            assert.ok(error);
            assert.ok(!error.errors['name']);
            assert.equal('Path `quest` is invalid (I seek the grail).',
              error.errors['quest'].message);
            assert.equal('`Yellow` is not a valid enum value for path `favoriteColor`.',
              error.errors['favoriteColor'].message);
            done();
          });
        });
      });
