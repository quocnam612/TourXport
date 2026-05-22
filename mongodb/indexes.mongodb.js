/* global use, db */

use("test");

db.places.createIndex(
    {
        source: 1,
        sourceLocationId: 1
    },
    {
        unique: true,
        partialFilterExpression: {
            sourceLocationId: {
                $exists: true,
                $type: "string"
            }
        },
        name: "unique_source_sourceLocationId"
    }
);