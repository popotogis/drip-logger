export interface BrewStep {
    waterAmount: number
    waitTime: number
}

export interface Recipe {
    id: string
    name: string
    beanWeightGrams: number
    grinder?: string
    grindSize: string
    dripper?: string
    filter?: string
    temperature?: number
    totalWaterAmount: number
    note?: string
    steps: BrewStep[]
    lastUsed: string
}

export const createDefaultRecipe = (): Omit<Recipe, 'id' | 'lastUsed'> => ({
    name: '',
    beanWeightGrams: 15,
    grindSize: '',
    totalWaterAmount: 0,
    steps: [],
})

