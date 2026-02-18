import { Recipe } from '@/types/recipe'
import { db } from '@/lib/firebase'
import {
    collection,
    doc,
    setDoc,
    getDoc,
    deleteDoc,
    DocumentData,
    FirestoreDataConverter,
    QueryDocumentSnapshot,
    SnapshotOptions,
    CollectionReference
} from 'firebase/firestore'
import { sign } from 'crypto'

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
            totalWaterAmount: recipe.totalWaterAmount || recipe.steps.reduce((acc, step) => acc + (Number(step.waterAmount) || 0), 0),
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

export async function createRecipe(uid: string, recipeData: Omit<Recipe, 'id' | 'lastUsed'>)
    : Promise<string> {
    const colRef = collection(db, 'users', uid, 'recipes').withConverter(recipeConverter)
    const docRef = doc(colRef)
    const newRecipe: Recipe = {
        ...recipeData,
        id: docRef.id,
        lastUsed: new Date().toISOString()
    }
    await setDoc(docRef, newRecipe)
    return docRef.id
}

export async function updateRecipe(uid: string, recipe: Recipe): Promise<void> {
    const docRef = doc(db, 'users', uid, 'recipes', recipe.id).withConverter(recipeConverter)
    await setDoc(docRef, {
        ...recipe,
        lastUsed: new Date().toISOString()
    })
}

export async function getRecipe(uid: string, recipeId: string): Promise<Recipe | null> {
    const docRef = doc(db, 'users', uid, 'recipes', recipeId).withConverter(recipeConverter)
    const snap = await getDoc(docRef)
    return snap.exists() ? snap.data() : null
}

// delete recipe
export async function deleteRecipe(uid: string, recipeId: string): Promise<void> {
    const docRef = doc(db, 'users', uid, 'recipes', recipeId).withConverter(recipeConverter)
    await deleteDoc(docRef)
}