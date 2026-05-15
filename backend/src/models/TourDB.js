import mongoose from 'mongoose';

const activitySchema = new mongoose.Schema({
    timeSlot: { 
        type: String, 
        required: true 
    },
    placeName: { 
        type: String, 
        required: true 
    },
    placeId: { 
        type: String
    },
    estimatedCost: { 
        type: Number, 
        default: 0 
    },
    rationale: { 
        type: String 
    }
});

const itineraryDaySchema = new mongoose.Schema({
    day: { 
        type: Number, 
        required: true 
    },
    activities: [activitySchema]
});

const tourSchema = new mongoose.Schema({
    userId: { 
        type: mongoose.Schema.Types.ObjectId, 
        ref: 'User', 
        required: true 
    },
    title: { type: String, default: 'Chuyến đi Vũng Tàu' }, // Tên tour để user dễ quản lý
    totalEstimatedCost: { type: Number, default: 0 },
    isFromDb: { type: Boolean, default: true },
    
    // Lưu lại input của User để sau này AI có thể "học" hoặc tái tạo lại
    userInput: {
        budget: { type: Number },
        duration_days: { type: Number },
        preferences: { type: String }
    },

    itinerary: [itineraryDaySchema]
}, { 
    timestamps: true
});

export default mongoose.model('TourDB', tourSchema, 'tours');