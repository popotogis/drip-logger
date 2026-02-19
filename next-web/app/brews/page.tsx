'use client'

import { useEffect, useState, Suspense, use } from 'react'
import { useRouter, useSearchParams } from 'next/navigation'
import { copyToClipboard } from '@/lib/utils'
import { auth } from '@/lib/firebase'
import { useAuthState } from 'react-firebase-hooks/auth'
import { getBrewResult, updateBrewResult, generateMarkdown } from '@/lib/brewResultUtils'
import { createRecipe, getRecipe } from '@/lib/recipeUtils'
import { BrewResult } from '@/types/brewResult'
import { Button } from '@/components/ui/button'
import { Textarea } from '@/components/ui/textarea'
import { ArrowLeft, Copy, Download, Home } from 'lucide-react'
import Link from 'next/link'
import { getBeans } from '@/lib/beanUtils'
import { Bean } from '@/types/bean'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'

export default function BrewResultPage() {
    return (
        <Suspense fallback={<div>Loading...</div>}>
            <BrewResultContent />
        </Suspense>
    )
}

function BrewResultContent() {
    const searchParams = useSearchParams()
    const id = searchParams.get('id')
    const [user, loading] = useAuthState(auth)
    const [result, setResult] = useState<BrewResult | null>(null)
    const [beans, setBeans] = useState<Bean[]>([])
    const [notes, setNotes] = useState('')
    const [selectedBeanId, setSelectedBeanId] = useState<string>('')
    const [isSaving, setIsSaving] = useState(false)
    const [isRecipeModified, setIsRecipeModified] = useState(false)
    const [isRecipeSaved, setIsRecipeSaved] = useState(false) // Track if user saved the recipe manually in this session
    const router = useRouter()

    useEffect(() => {
        if (user && id) {
            getBrewResult(user.uid, id).then(async res => {
                if (res) {
                    setResult(res)
                    setNotes(res.notes)
                    if (res.bean) setSelectedBeanId(res.bean.id)

                    // Check if recipe is modified compared to storage
                    if (res.recipe.id && res.recipe.id !== 'temp') {
                        const original = await getRecipe(user.uid, res.recipe.id)
                        if (original) {
                            // Compare relevant fields
                            const currentJson = JSON.stringify({ ...res.recipe, id: '', lastUsed: '' })
                            const originalJson = JSON.stringify({ ...original, id: '', lastUsed: '' })
                            if (currentJson !== originalJson) {
                                setIsRecipeModified(true)
                            }
                        } else {
                            // Original not found (orphaned)
                            setIsRecipeModified(true)
                        }
                    } else {
                        // Temp recipe
                        setIsRecipeModified(true)
                    }
                }
            })
            getBeans(user.uid).then(setBeans)
        }
    }, [user, id])

    const handleSave = async () => {
        if (!user || !result) return
        setIsSaving(true)

        const selectedBean = beans.find(b => b.id === selectedBeanId)
        const updatedResult: BrewResult = {
            ...result,
            bean: selectedBean,
            notes: notes
        }

        await updateBrewResult(user.uid, updatedResult)
        setResult(updatedResult)
        setIsSaving(false)
        return updatedResult
    }

    const handleCopyMarkdown = async () => {
        if (!selectedBeanId) {
            alert('Please select a bean first.')
            return
        }
        const updated = await handleSave()
        if (updated) {
            const md = generateMarkdown(updated)
            const success = await copyToClipboard(md)
            if (success) {
                alert('Copied Markdown to clipboard')
            } else {
                alert('Failed to copy. Please copy manually.')
            }
        }
    }

    const handleDownloadMarkdown = async () => {
        if (!selectedBeanId) {
            alert('Please select a bean first.')
            return
        }
        const updated = await handleSave()
        if (updated) {
            const md = generateMarkdown(updated)
            const date = updated.brewedAt.toDate()

            const yyyy = date.getFullYear()
            const mm = (date.getMonth() + 1).toString().padStart(2, '0')
            const dd = date.getDate().toString().padStart(2, '0')
            const hh = date.getHours().toString().padStart(2, '0')
            const min = date.getMinutes().toString().padStart(2, '0')
            const beanName = updated.bean?.name.replace(/[<>:"/\\|?*]/g, '_') || 'NoBean'

            const filename = `${yyyy}${mm}${dd}_${hh}${min}_${beanName}.md`
            const blob = new Blob([md], { type: 'text/markdown' })
            const url = URL.createObjectURL(blob)
            const a = document.createElement('a')
            a.href = url
            a.download = filename
            a.click()
            URL.revokeObjectURL(url)
        }
    }

    const handleSaveRecipe = async () => {
        if (!user || !result) return
        try {
            const { id: _, ...recipeData } = result.recipe
            await createRecipe(user.uid, {
                ...recipeData,
                name: `${result.recipe.name} (from Brew)`
            })
            setIsRecipeSaved(true)
            alert('Recipe saved successfully!')
        } catch (e) {
            console.error(e)
            alert('Failed to save recipe')
        }
    }

    const isDirty = isRecipeModified && !isRecipeSaved

    const handleHomeClick = (e: React.MouseEvent) => {
        if (isDirty) {
            if (!confirm('This brew uses a modified recipe. Do you want to leave without saving the recipe?')) {
                e.preventDefault()
            }
        }
    }

    if (loading || !result) return <div className="p-8">Loading...</div>
    return (
        <div className="container mx-auto py-10 px-4 max-w-3xl">
            <div className="mb-6 flex justify-between items-center">
                <Link href="/" onClick={handleHomeClick}>
                    <Button variant="ghost" className="pl-0">
                        <Home className="mr-2 h-4 w-4" />
                        Home
                    </Button>
                </Link>
                <h1 className="text-2xl font-bold">Brew Result</h1>
            </div>
            <div className="bg-white p-6 rounded-lg shadow-sm border space-y-8">
                {/* Summary */}
                <div className="text-center space-y-2">
                    <h2 className="text-xl font-bold">{result.recipe.name}</h2>
                    <p className="text-4xl font-mono font-bold">
                        {Math.floor(result.totalTimeMs / 60000)}:
                        {((result.totalTimeMs % 60000) / 1000).toFixed(0).padStart(2, '0')}
                    </p>
                    <p className="text-gray-500">
                        {result.brewedAt.toDate().toLocaleString()}
                    </p>
                </div>
                {/* Bean Selection */}
                <div className="space-y-2">
                    <label className="text-sm font-medium">Select Bean <span className="text-red-500">*</span></label>
                    <Select value={selectedBeanId} onValueChange={setSelectedBeanId}>
                        <SelectTrigger>
                            <SelectValue placeholder="Select a bean..." />
                        </SelectTrigger>
                        <SelectContent>
                            {beans.map(bean => (
                                <SelectItem key={bean.id} value={bean.id}>
                                    {bean.name} ({bean.roaster})
                                </SelectItem>
                            ))}
                        </SelectContent>
                    </Select>
                </div>
                {/* Notes */}
                <div className="space-y-2">
                    <label className="text-sm font-medium">Tasting Notes</label>
                    <Textarea
                        value={notes}
                        onChange={e => setNotes(e.target.value)}
                        placeholder="Taste, Aroma, Body, etc..."
                        rows={5}
                    />
                </div>
                {/* Details Table */}
                <div>
                    <h3 className="font-bold mb-2">Step Details</h3>
                    <div className="overflow-x-auto">
                        <table className="w-full text-sm text-left">
                            <thead className="bg-gray-100">
                                <tr>
                                    <th className="p-2">#</th>
                                    <th className="p-2">Water</th>
                                    <th className="p-2">Plan</th>
                                    <th className="p-2">Actual</th>
                                    <th className="p-2">Diff</th>
                                </tr>
                            </thead>
                            <tbody>
                                {result.steps.map((step, i) => {
                                    const diff = Math.round((step.actualTimeMs - step.plannedTimeMs) / 1000)
                                    const diffColor = Math.abs(diff) > 5 ? 'text-red-500' : 'text-gray-600'
                                    return (
                                        <tr key={i} className="border-b">
                                            <td className="p-2">{step.stepIndex + 1}</td>
                                            <td className="p-2">{step.waterAmount}ml</td>
                                            <td className="p-2">{Math.round(step.plannedTimeMs / 1000)}s</td>
                                            <td className="p-2">{Math.round(step.actualTimeMs / 1000)}s</td>
                                            <td className={`p-2 ${diffColor}`}>
                                                {diff > 0 ? `+${diff}` : diff}s
                                            </td>
                                        </tr>
                                    )
                                })}
                            </tbody>
                        </table>
                    </div>
                </div>
                {/* Actions */}
                <div className="flex flex-col gap-3 pt-4 border-t">
                    <Button onClick={handleSaveRecipe} className="w-full bg-orange-600 hover:bg-orange-700 text-white">
                        Save Recipe
                    </Button>

                    <Button onClick={handleCopyMarkdown} className="w-full" variant="secondary">
                        <Copy className="mr-2 h-4 w-4" />
                        Copy as Markdown
                    </Button>

                    <Button onClick={handleDownloadMarkdown} variant="outline" className="w-full">
                        <Download className="mr-2 h-4 w-4" />
                        Download Markdown File
                    </Button>
                </div>
            </div>
        </div>
    )
}