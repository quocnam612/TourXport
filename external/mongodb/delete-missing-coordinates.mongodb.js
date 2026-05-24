/* global use, db */

use("test");

const collections = [
    "places",
    "hotels",
    "restaurants"
];

const invalidCoordinatesFilter = {
    $expr: {
        $not: {
            $and: [
                {
                    $isArray: "$location.coordinates"
                },
                {
                    $eq: [
                        {
                            $size: "$location.coordinates"
                        },
                        2
                    ]
                },
                {
                    $allElementsTrue: {
                        $map: {
                            input: "$location.coordinates",
                            as: "coordinate",
                            in: {
                                $in: [
                                    {
                                        $type: "$$coordinate"
                                    },
                                    [
                                        "double",
                                        "int",
                                        "long",
                                        "decimal"
                                    ]
                                ]
                            }
                        }
                    }
                }
            ]
        }
    }
};

collections.forEach((collectionName) => {
    const collection = db.getCollection(collectionName);
    const count = collection.countDocuments(invalidCoordinatesFilter);

    print(`${collectionName}: deleting ${count} documents without valid coordinates`);

    if (count > 0) {
        const result = collection.deleteMany(invalidCoordinatesFilter);
        print(`${collectionName}: deleted ${result.deletedCount} documents`);
    }
});
