import { Recipe } from '@/types/recipe'
import { DocumentData, FirestoreDataConverter, QueryDocumentSnapshot, SnapshotOptions } from 'firebase/firestore'

export const recipeConverter: FirestoreDataConverter<Recipe> = {
    toFirestore(recipe: Recipe): DocumentData {
        return {
            id: recipe.id,
            name: recipe.name,
            beanWeightGrams: recipe.beanWeightGrams,
            grinder: recipe.grinder || null,
            grindSize: recipe.grindSize,
            dripper: recipe.dripper || null,
            filter: recipe.filter || null,
            temperature: recipe.temperature || null,
            totalWaterAmount: recipe.totalWaterAmount,
            note: recipe.note || null,
            steps: recipe.steps.map((step) => ({
                waterAmount: step.waterAmount,
                waitTime: step.waitTime,
            })),
            lastUsed: recipe.lastUsed,
        }
    },
    fromFirestore(
        snapshot: QueryDocumentSnapshot,
        options: SnapshotOptions
    ): Recipe {
        const data = snapshot.data(options)
        return {
            id: snapshot.id,
            name: data.name,
            beanWeightGrams: data.beanWeightGrams,
            grinder: data.grinder,
            grindSize: data.grindSize,
            dripper: data.dripper,
            filter: data.filter,
            temperature: data.temperature,
            totalWaterAmount: data.totalWaterAmount,
            note: data.note,
            steps: Array.isArray(data.steps)
                ? data.steps.map((s: any) => ({
                    waterAmount: Number(s.waterAmount),
                    waitTime: Number(s.waitTime),
                }))
                : [],
            lastUsed: data.lastUsed || new Date().toISOString(),
        }
    }
}