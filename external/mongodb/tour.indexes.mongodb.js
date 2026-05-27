/* global use, db */

use("test");

db.tours.createIndex(
    {
        userId: 1
    },
    {
        name: "userId_1"
    }
);

db.tours.createIndex(
    {
        title: "text",
        destinations: "text"
    },
    {
        name: "title_text_destinations_text"
    }
);

db.tours.createIndex(
    {
        destinations: 1
    },
    {
        name: "destinations_1"
    }
);

db.tours.createIndex(
    {
        visibility: 1
    },
    {
        name: "visibility_1"
    }
);

db.tours.createIndex(
    {
        totalDays: 1
    },
    {
        name: "totalDays_1"
    }
);

db.tours.createIndex(
    {
        totalNights: 1
    },
    {
        name: "totalNights_1"
    }
);

db.tours.createIndex(
    {
        totalDistanceMeters: 1
    },
    {
        name: "totalDistanceMeters_1"
    }
);

db.tours.createIndex(
    {
        "travelers.adults": 1,
        "travelers.children": 1
    },
    {
        name: "travelers_adults_1_travelers_children_1"
    }
);

db.tours.createIndex(
    {
        "preferences.budgetLevel": 1,
        "preferences.transportMode": 1,
        "preferences.pace": 1
    },
    {
        name: "preferences_budgetLevel_1_preferences_transportMode_1_preferences_pace_1"
    }
);

db.tours.createIndex(
    {
        "preferences.interests": 1
    },
    {
        name: "preferences_interests_1"
    }
);

db.tours.createIndex(
    {
        "estimatedCost.min": 1,
        "estimatedCost.max": 1,
        "estimatedCost.currency": 1
    },
    {
        name: "estimatedCost_min_1_estimatedCost_max_1_estimatedCost_currency_1"
    }
);
