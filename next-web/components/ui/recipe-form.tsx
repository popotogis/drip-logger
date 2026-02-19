'use client'

import { useFieldArray, useForm, DefaultValues } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { useState } from 'react'
import * as z from 'zod'
import { Button } from '@/components/ui/button'
import { Switch } from '@/components/ui/switch'
import {
    Form,
    FormControl,
    FormField,
    FormItem,
    FormLabel,
    FormMessage,
} from '@/components/ui/form'
import { Input } from '@/components/ui/input'
import { Textarea } from '@/components/ui/textarea'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Trash2, Plus } from 'lucide-react'

// Define schema inside or outside component
const brewStepSchema = z.object({
    waterAmount: z.coerce.number().min(0, 'Must be positive'),
    waitTime: z.coerce.number().min(0, 'Must be positive'),
})

const recipeSchema = z.object({
    name: z.string().min(1, 'Name is required'),
    beanWeightGrams: z.coerce.number().min(0.1, 'Min 0.1g'),
    grinder: z.string().optional(),
    grindSize: z.string().min(1, 'Grind size is required'),
    dripper: z.string().optional(),
    filter: z.string().optional(),
    temperature: z.coerce.number().optional(),
    note: z.string().optional(),
    steps: z.array(brewStepSchema),
})

type RecipeFormValues = z.infer<typeof recipeSchema>

interface RecipeFormProps {
    defaultValues?: Partial<RecipeFormValues>
    onSubmit: (data: RecipeFormValues) => void
    onStartBrewing?: (data: RecipeFormValues) => void
    onSaveAsCopy?: (data: RecipeFormValues) => void
    isSubmitting?: boolean
}

export function RecipeForm({
    defaultValues,
    onSubmit,
    onStartBrewing,
    onSaveAsCopy,
    isSubmitting = false,
}: RecipeFormProps) {
    // Explicitly type DefaultValues to match RecipeFormValues
    // We need to ensure that the types match exactly 
    const initialValues: DefaultValues<RecipeFormValues> = {
        name: defaultValues?.name || '',
        beanWeightGrams: defaultValues?.beanWeightGrams || 15,
        grindSize: defaultValues?.grindSize || '',
        grinder: defaultValues?.grinder || '',
        dripper: defaultValues?.dripper || '',
        filter: defaultValues?.filter || '',
        temperature: defaultValues?.temperature,
        note: defaultValues?.note || '',
        steps: defaultValues?.steps?.map(s => ({
            waterAmount: Number(s.waterAmount),
            waitTime: Number(s.waitTime)
        })) || [],
    }

    const form = useForm<RecipeFormValues>({
        resolver: zodResolver(recipeSchema) as any,
        defaultValues: initialValues,
        mode: 'onChange',
    })

    const { fields, append, remove, replace } = useFieldArray({
        control: form.control,
        name: 'steps',
    })

    const [isRatioLocked, setIsRatioLocked] = useState(true)

    const steps = form.watch('steps')
    const beanWeight = form.watch('beanWeightGrams')
    const totalWater = steps?.reduce(
        (sum, step) => sum + (Number(step.waterAmount) || 0),
        0
    )
    const ratio = (beanWeight && beanWeight > 0) ? (totalWater / beanWeight) : 0
    const ratioDisplay = ratio > 0 ? `(1:${Number.isInteger(ratio) ? ratio : ratio.toFixed(1)})` : ''


    return (
        <Form {...form}>
            <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-8">
                <div className="grid gap-6 md:grid-cols-2">
                    {/* basic info*/}
                    <Card>
                        <CardHeader>
                            <CardTitle>Basic Info</CardTitle>
                        </CardHeader>
                        <CardContent className="space-y-4">
                            <FormField
                                control={form.control}
                                name="name"
                                render={({ field }) => (
                                    <FormItem>
                                        <FormLabel>Recipe Name</FormLabel>
                                        <FormControl>
                                            <Input placeholder="4:6 Method" {...field} />
                                        </FormControl>
                                        <FormMessage />
                                    </FormItem>
                                )}
                            />
                            <FormField
                                control={form.control}
                                name="note"
                                render={({ field }) => (
                                    <FormItem>
                                        <FormLabel>Note</FormLabel>
                                        <FormControl>
                                            <Textarea placeholder="Tasting notes..." {...field} />
                                        </FormControl>
                                        <FormMessage />
                                    </FormItem>
                                )}
                            />
                        </CardContent>
                    </Card>

                    {/* params */}
                    <Card>
                        <CardHeader>
                            <CardTitle>Parameters</CardTitle>
                        </CardHeader>
                        <CardContent className="space-y-4">
                            <div className="grid grid-cols-2 gap-4">
                                <FormField
                                    control={form.control}
                                    name="beanWeightGrams"
                                    render={({ field }) => (
                                        <FormItem>
                                            <div className="flex items-center justify-between">
                                                <FormLabel>Beans (g)</FormLabel>
                                                <div className="flex items-center space-x-2">
                                                    <Switch
                                                        checked={isRatioLocked}
                                                        onCheckedChange={setIsRatioLocked}
                                                        id="ratio-lock"
                                                    />
                                                    <label htmlFor="ratio-lock" className="text-xs text-muted-foreground cursor-pointer">
                                                        Lock Ratio
                                                    </label>
                                                </div>
                                            </div>
                                            <FormControl>
                                                <Input
                                                    type="number"
                                                    step="0.1"
                                                    {...field}
                                                    onChange={(e) => {
                                                        const newValue = parseFloat(e.target.value)
                                                        const oldValue = Number(field.value) // Ensure it's a number

                                                        // Update the field first
                                                        field.onChange(e)

                                                        if (isRatioLocked && oldValue > 0 && !isNaN(newValue) && newValue > 0) {
                                                            const ratio = newValue / oldValue
                                                            const currentSteps = form.getValues('steps') || []
                                                            const newSteps = currentSteps.map(step => ({
                                                                ...step,
                                                                waterAmount: Math.round(Number(step.waterAmount) * ratio)
                                                            }))
                                                            // Use replace from useFieldArray for better performance and correctness
                                                            // form.setValue('steps', newSteps) is not recommended for Field Arrays
                                                            replace(newSteps)
                                                        }
                                                    }}
                                                />
                                            </FormControl>
                                            <FormMessage />
                                        </FormItem>
                                    )}
                                />
                                <FormItem>
                                    <FormLabel>Total Water (g)</FormLabel>
                                    <FormControl>
                                        <Input value={`${totalWater} ${ratioDisplay}`} readOnly disabled className="bg-muted" />

                                    </FormControl>
                                </FormItem>
                            </div>

                            <div className="grid grid-cols-2 gap-4">
                                <FormField
                                    control={form.control}
                                    name="temperature"
                                    render={({ field }) => (
                                        <FormItem>
                                            <FormLabel>Temp (°C)</FormLabel>
                                            <FormControl>
                                                <Input type="number" placeholder="Optional" {...field} value={field.value || ''} />
                                            </FormControl>
                                            <FormMessage />
                                        </FormItem>
                                    )}
                                />
                                <FormField
                                    control={form.control}
                                    name="grindSize"
                                    render={({ field }) => (
                                        <FormItem>
                                            <FormLabel>Grind Size</FormLabel>
                                            <FormControl>
                                                <Input placeholder="Medium-Fine, 20clicks..." {...field} />
                                            </FormControl>
                                            <FormMessage />
                                        </FormItem>
                                    )}
                                />
                            </div>
                            <div className="grid grid-cols-2 gap-4">
                                <FormField
                                    control={form.control}
                                    name="grinder"
                                    render={({ field }) => (
                                        <FormItem>
                                            <FormLabel>Grinder</FormLabel>
                                            <FormControl>
                                                <Input placeholder="Optional" {...field} />
                                            </FormControl>
                                            <FormMessage />
                                        </FormItem>
                                    )}
                                />
                                <FormField
                                    control={form.control}
                                    name="dripper"
                                    render={({ field }) => (
                                        <FormItem>
                                            <FormLabel>Dripper</FormLabel>
                                            <FormControl>
                                                <Input placeholder="Optional" {...field} />
                                            </FormControl>
                                            <FormMessage />
                                        </FormItem>
                                    )}
                                />
                            </div>
                            <FormField
                                control={form.control}
                                name="filter"
                                render={({ field }) => (
                                    <FormItem>
                                        <FormLabel>Filter</FormLabel>
                                        <FormControl>
                                            <Input placeholder="Optional" {...field} />
                                        </FormControl>
                                        <FormMessage />
                                    </FormItem>
                                )}
                            />
                        </CardContent>
                    </Card>
                </div>

                {/* steps */}
                <Card>
                    <CardHeader className="flex flex-row items-center justify-between">
                        <CardTitle>Pouring Steps</CardTitle>
                        <div className="text-sm font-medium text-muted-foreground">
                            Total: {totalWater}g
                        </div>
                    </CardHeader>
                    <CardContent className="space-y-4">
                        {fields.map((field, index) => (
                            <div key={field.id} className="flex items-end gap-4">
                                <div className="flex-1 grid grid-cols-2 gap-4">
                                    <FormField
                                        control={form.control}
                                        name={`steps.${index}.waterAmount`}
                                        render={({ field }) => (
                                            <FormItem>
                                                <FormLabel className={index !== 0 ? 'sr-only' : ''}>water (g)</FormLabel>
                                                <FormControl>
                                                    <Input type="number" step="1" {...field} />
                                                </FormControl>
                                                <FormMessage />
                                            </FormItem>
                                        )}
                                    />
                                    <FormField
                                        control={form.control}
                                        name={`steps.${index}.waitTime`}
                                        render={({ field }) => (
                                            <FormItem>
                                                <FormLabel className={index !== 0 ? 'sr-only' : ''}>wait (sec)</FormLabel>
                                                <FormControl>
                                                    <Input type="number" step="1" {...field} />
                                                </FormControl>
                                            </FormItem>
                                        )}
                                    />
                                </div>
                                <Button
                                    type="button"
                                    variant="ghost"
                                    size="icon"
                                    className="mb-0.5"
                                    onClick={() => remove(index)}
                                >
                                    <Trash2 className="h-4 w-4" />
                                </Button>
                            </div>
                        ))}
                        <Button
                            type="button"
                            variant="outline"
                            size="sm"
                            className="mt-2"
                            onClick={() => append({ waterAmount: 0, waitTime: 0 })}
                        >
                            <Plus className="mr-2 h-4 w-4" />
                            Add Step
                        </Button>
                    </CardContent>
                </Card>

                <div className="flex justify-end gap-2">
                    {onSaveAsCopy && (
                        <Button type="button" variant="ghost" onClick={form.handleSubmit(onSaveAsCopy)} disabled={isSubmitting}>
                            Save as New
                        </Button>
                    )}
                    <Button type="submit" variant="secondary" disabled={isSubmitting}>
                        {isSubmitting ? 'Saving...' : 'Save (Update)'}
                    </Button>
                    {onStartBrewing && (
                        <Button type="button" size="lg" className="font-bold flex-1 md:flex-none" onClick={form.handleSubmit(onStartBrewing)} disabled={isSubmitting}>
                            Start Brewing
                        </Button>
                    )}
                </div>
            </form>
        </Form>
    )
}