import { db } from '@/lib/firebase'
import { BrewResult } from '@/types/brewResult'
import {
    collection,
    doc,
    setDoc,
    getDoc,
    FirestoreDataConverter,
    serverTimestamp,
} from 'firebase/firestore'

const brewResultConverter: FirestoreDataConverter<BrewResult> = {
    toFirestore(result: BrewResult) {
        return result
    },
    fromFirestore(snapshot, options) {
        const data = snapshot.data(options)
        return {
            id: snapshot.id,
            ...data,
        } as BrewResult
    }
}

// Firestore operations
export async function createBrewResult(uid: string, result: BrewResult): Promise<void> {
    const docRef = doc(db, 'users', uid, 'brewResults', result.id).withConverter(brewResultConverter)
    await setDoc(docRef, result)
}

export async function getBrewResult(uid: string, resultId: string): Promise<BrewResult | null> {
    const docRef = doc(db, 'users', uid, 'brewResults', resultId).withConverter(brewResultConverter)
    const snap = await getDoc(docRef)
    return snap.exists() ? snap.data() : null
}

export async function updateBrewResult(uid: string, result: BrewResult): Promise<void> {
    const docRef = doc(db, 'users', uid, 'brewResults', result.id).withConverter(brewResultConverter)
    await setDoc(docRef, result, { merge: true })
}

// generate markdown
function formatDuration(ms: number): string {
    const totalSeconds = Math.floor(ms / 1000)
    const minutes = Math.floor(totalSeconds / 60)
    const seconds = totalSeconds % 60
    return `${minutes}:${seconds.toString().padStart(2, '0')}`
}

export function generateMarkdown(result: BrewResult): string {
    const buffer: string[] = []

    buffer.push(`# ${result.recipe.name}`)
    buffer.push('')

    // bean info
    buffer.push('## 豆の情報')
    if (result.bean) {
        buffer.push(`- **名称**: ${result.bean.name}`)
        buffer.push(`- **焙煎所**: ${result.bean.roaster}`)
        if (result.bean.roastDate) {
            buffer.push(`- **焙煎日**: ${result.bean.roastDate}`)
        }

        const originVariety = [
            result.bean.origin,
            result.bean.variety,
        ].filter(Boolean).join(' / ')

        buffer.push(`- **産地/品種**: ${originVariety || '-'}`)
        buffer.push(`- **焙煎度**: ${result.bean.roastLevel || '-'}`)
        buffer.push(`- **精製方法**: ${result.bean.process}`)
    } else {
        buffer.push('- **名称**: -')
        buffer.push('- **焙煎所**: -')
        buffer.push('- **産地/品種**: -')
        buffer.push('- **焙煎度**: -')
        buffer.push('- **精製方法**: -')
    }
    buffer.push('')

    // extraction params
    buffer.push('## 抽出パラメータ')
    buffer.push(`- **使用量**: 豆 ${result.recipe.beanWeightGrams}g / 湯 ${result.recipe.totalWaterAmount}ml`)
    buffer.push(`- **挽き目**: ${result.recipe.grindSize} (${result.recipe.grinder || `-`})`)
    buffer.push(`- **温度**: ${result.recipe.temperature?.toFixed(1) ?? '-'}℃`)

    const gear = [
        result.recipe.dripper,
        result.recipe.filter,
    ].filter(Boolean).join(' / ')

    buffer.push(`- **器具**: ${gear || '-'}`)
    buffer.push('')

    // extraction result
    buffer.push('## 抽出結果 (実績)')
    const plannedTotalSeconds = result.recipe.steps.reduce((acc, step) => acc + step.waitTime, 0)

    const date = result.brewedAt.toDate()
    const dateStr = `${date.getFullYear()}/${(date.getMonth() + 1).toString().padStart(2, '0')}/${date.getDate().toString().padStart(2, '0')}`

    buffer.push(`- **合計時間**: ${formatDuration(result.totalTimeMs)} (計画: ${formatDuration(plannedTotalSeconds * 1000)})`)
    buffer.push(`- **抽出日**: ${dateStr}`)
    buffer.push('')
    // step details
    buffer.push('### 抽出ペース詳細')
    buffer.push('| Step | 湯量 | 計画時間 | 実績時間 | 差異 |')
    buffer.push('| :--- | :--- | :--- | :--- | :--- |')

    result.steps.forEach(step => {
        const diffSeconds = Math.round((step.actualTimeMs - step.plannedTimeMs) / 1000)
        let diffStr = '±0'
        if (diffSeconds > 0) diffStr = `+${diffSeconds}`
        else if (diffSeconds < 0) diffStr = `${diffSeconds}`
        buffer.push(`| ${step.stepIndex + 1} | ${step.waterAmount}ml | ${Math.round(step.plannedTimeMs / 1000)}s | ${Math.round(step.actualTimeMs / 1000)}s | ${diffStr}s |`)
    })
    buffer.push('')
    // notes
    buffer.push('## テイスティングノート / メモ')
    buffer.push(`> ${result.notes || '-'}`)
    return buffer.join('\n')
}