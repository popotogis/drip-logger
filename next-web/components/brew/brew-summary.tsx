'use client'

import { useState } from 'react'
import { copyToClipboard } from '@/lib/utils'
import { BrewResult } from '@/types/brewResult'
import { generateMarkdown } from '@/lib/brewResultUtils'
import { Button } from '@/components/ui/button'
import { Textarea } from '@/components/ui/textarea'
import { Copy, Download, Plus } from 'lucide-react'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog'
import { BeanForm } from '@/components/ui/bean-form'
import { useBeans } from '@/hooks/useBeans'
import { useRecipe } from '@/hooks/useRecipe'

interface BrewSummaryProps {
    uid: string
    initialResult: BrewResult
    onSaveBrewResult: (updatedData: BrewResult) => Promise<void>
}

export function BrewSummary({ uid, initialResult, onSaveBrewResult }: BrewSummaryProps) {
    const { beans: fetchedBeans, addBean } = useBeans(uid)
    const { saveRecipe } = useRecipe(uid)

    const [result, setResult] = useState<BrewResult>(initialResult)
    const [notes, setNotes] = useState(initialResult.notes)
    const [selectedBeanId, setSelectedBeanId] = useState<string>(initialResult.bean?.id || '')
    const [isSaving, setIsSaving] = useState(false)
    const [isRecipeSaved, setIsRecipeSaved] = useState(false)
    const [isBeanDialogOpen, setIsBeanDialogOpen] = useState(false)

    const handleSave = async () => {
        if (!result) return null
        setIsSaving(true)

        const selectedBean = fetchedBeans.find(b => b.id === selectedBeanId)
        const updatedResult: BrewResult = {
            ...result,
            bean: selectedBean,
            notes: notes
        }

        await onSaveBrewResult(updatedResult)
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
        if (!result) return
        try {
            const { id: _, ...recipeData } = result.recipe
            await saveRecipe({
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

    const handleCreateBean = async (data: any) => {
        try {
            const newBeanId = await addBean(data)
            setSelectedBeanId(newBeanId)
            setIsBeanDialogOpen(false)
            alert('Bean created successfully!')
        } catch (e) {
            console.error(e)
            alert('Failed to create bean')
        }
    }

    return (
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
                <div className="flex gap-2">
                    <Select value={selectedBeanId} onValueChange={setSelectedBeanId}>
                        <SelectTrigger className="flex-1">
                            <SelectValue placeholder="Select a bean..." />
                        </SelectTrigger>
                        <SelectContent>
                            {fetchedBeans.map(bean => (
                                <SelectItem key={bean.id} value={bean.id}>
                                    {bean.name} ({bean.roaster})
                                </SelectItem>
                            ))}
                        </SelectContent>
                    </Select>
                    <Dialog open={isBeanDialogOpen} onOpenChange={setIsBeanDialogOpen}>
                        <DialogTrigger asChild>
                            <Button variant="outline" size="sm" className="h-10 px-3">
                                <Plus className="mr-1 h-4 w-4" />
                                New
                            </Button>
                        </DialogTrigger>
                        <DialogContent className="sm:max-w-[425px] max-h-[85vh] overflow-y-auto">
                            <DialogHeader>
                                <DialogTitle>Add New Bean</DialogTitle>
                            </DialogHeader>
                            <div className="py-4">
                                <BeanForm onSubmit={handleCreateBean} />
                            </div>
                        </DialogContent>
                    </Dialog>
                </div>
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
                {isRecipeSaved ? (
                    <Button disabled className="w-full bg-orange-600/50 text-white">
                        Recipe Saved
                    </Button>
                ) : (
                    <Button onClick={handleSaveRecipe} className="w-full bg-orange-600 hover:bg-orange-700 text-white">
                        Save Recipe
                    </Button>
                )}

                <Button onClick={handleCopyMarkdown} className="w-full" variant="secondary" disabled={isSaving}>
                    <Copy className="mr-2 h-4 w-4" />
                    Copy as Markdown
                </Button>

                <Button onClick={handleDownloadMarkdown} variant="outline" className="w-full" disabled={isSaving}>
                    <Download className="mr-2 h-4 w-4" />
                    Download Markdown File
                </Button>
            </div>
        </div>
    )
}
