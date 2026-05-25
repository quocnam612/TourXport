/* global use, db */

use("test");

const placeLikeCollections = [
    db.places,
    db.hotels,
    db.restaurants
];

placeLikeCollections.forEach((collection) => {
    collection.createIndex(
        {
            location: "2dsphere"
        },
        {
            name: "location_2dsphere"
        }
    );

    collection.createIndex(
        {
            city: 1
        },
        {
            name: "city_1"
        }
    );

    collection.createIndex(
        {
            category: 1
        },
        {
            name: "category_1"
        }
    );

    collection.createIndex(
        {
            tags: 1
        },
        {
            name: "tags_1"
        }
    );

    collection.createIndex(
        {
            title: "text",
            description: "text",
            city: "text",
            state: "text",
            category: "text",
            categories: "text",
            tags: "text",
            searchText: "text"
        },
        {
            name: "title_text_description_text_city_text_state_text_category_text_categories_text_tags_text_searchText_text"
        }
    );

    collection.createIndex(
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
});
