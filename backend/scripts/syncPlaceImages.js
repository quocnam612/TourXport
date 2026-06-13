import fs from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import mongoose from 'mongoose';

import config from '../src/config/config.js';
import PlaceDB from '../src/models/PlaceDB.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const repoRoot = path.resolve(__dirname, '..', '..');
const defaultInput = path.join(repoRoot, 'crawler', 'data', 'places', 'VIETNAM-2932.json');

const inputPath = path.resolve(process.argv[2] || defaultInput);

const normalizeImage = (item) => {
    if (typeof item === 'string') {
        return item.trim()
            ? { url: item.trim(), publicId: null, source: 'tripadvisor' }
            : null;
    }

    if (!item || typeof item !== 'object') {
        return null;
    }

    const url = String(item.url || '').trim();
    if (!url) {
        return null;
    }

    return {
        url,
        publicId: item.publicId ?? null,
        source: item.source || 'tripadvisor'
    };
};

const uniqueImages = (items) => {
    const seen = new Set();
    const images = [];

    for (const item of Array.isArray(items) ? items : []) {
        const image = normalizeImage(item);
        if (!image || seen.has(image.url)) {
            continue;
        }
        seen.add(image.url);
        images.push(image);
    }

    return images;
};

const main = async () => {
    if (!config.database.uri) {
        throw new Error('MONGO_URI or MONGO_URI_TEST is required');
    }

    const raw = await fs.readFile(inputPath, 'utf8');
    const places = JSON.parse(raw);
    if (!Array.isArray(places)) {
        throw new Error(`Expected top-level JSON array: ${inputPath}`);
    }

    const operations = [];
    for (const place of places) {
        const sourceLocationId = String(place?.sourceLocationId || '').trim();
        const images = uniqueImages(place?.images);
        if (!sourceLocationId || images.length === 0) {
            continue;
        }

        operations.push({
            updateOne: {
                filter: { sourceLocationId },
                update: { $set: { images } }
            }
        });
    }

    console.log(`Input: ${inputPath}`);
    console.log(`Place image updates prepared: ${operations.length}`);

    if (operations.length === 0) {
        return;
    }

    await mongoose.connect(config.database.uri);
    try {
        let matched = 0;
        let modified = 0;
        const batchSize = 500;

        for (let index = 0; index < operations.length; index += batchSize) {
            const batch = operations.slice(index, index + batchSize);
            const result = await PlaceDB.bulkWrite(batch, { ordered: false });
            matched += result.matchedCount || 0;
            modified += result.modifiedCount || 0;
            console.log(`Synced ${Math.min(index + batch.length, operations.length)}/${operations.length}`);
        }

        console.log(`Done. Matched: ${matched}, modified: ${modified}`);
    } finally {
        await mongoose.disconnect();
    }
};

main().catch(async (error) => {
    console.error(error.message || error);
    await mongoose.disconnect().catch(() => {});
    process.exit(1);
});
