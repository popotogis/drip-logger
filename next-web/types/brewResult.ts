import { Recipe } from './recipe'
import { Bean } from './bean'
import { Timestamp } from 'firebase/firestore'

export interface BrewResultStep {
    stepIndex: number
    plannedTimeMs: number
    actualTimeMs: number
    waterAmount: number
}

export interface BrewResult {
    id: string
    recipe: Recipe
    bean?: Bean
    brewedAt: Timestamp
    steps: BrewResultStep[]
    totalTimeMs: number
    notes: string
}