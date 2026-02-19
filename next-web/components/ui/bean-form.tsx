'use client'

import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import * as z from 'zod'
import { Button } from '@/components/ui/button'
import { Form, FormControl, FormField, FormItem, FormLabel, FormMessage } from '@/components/ui/form'
import { Input } from '@/components/ui/input'
import { Textarea } from '@/components/ui/textarea'
import { Bean } from '@/types/bean'

const beanSchema = z.object({
    name: z.string().min(1, 'Name is required'),
    roaster: z.string().min(1, 'Roaster is required'),
    origin: z.string().optional(),
    roastLevel: z.string().optional(),
    process: z.string().optional(),
    variety: z.string().optional(),
    roastDate: z.string().optional(), // YYYY-MM-DD
    note: z.string().optional(),
})

type BeanFormValues = z.infer<typeof beanSchema>

interface BeanFormProps {
    defaultValues?: Partial<Bean>
    onSubmit: (data: BeanFormValues) => Promise<void>
}

export function BeanForm({ defaultValues, onSubmit }: BeanFormProps) {
    const form = useForm<BeanFormValues>({
        resolver: zodResolver(beanSchema),
        defaultValues: {
            name: defaultValues?.name || '',
            roaster: defaultValues?.roaster || '',
            origin: defaultValues?.origin || '',
            roastLevel: defaultValues?.roastLevel || '',
            process: defaultValues?.process || '',
            variety: defaultValues?.variety || '',
            roastDate: defaultValues?.roastDate || '',
            note: defaultValues?.note || '',
        }
    })

    return (
        <Form {...form}>
            <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-6">
                <FormField
                    control={form.control}
                    name="name"
                    render={({ field }) => (
                        <FormItem>
                            <FormLabel>Bean Name</FormLabel>
                            <FormControl><Input placeholder="Ethiopia Yirgacheffe" {...field} /></FormControl>
                            <FormMessage />
                        </FormItem>
                    )}
                />

                <div className="grid grid-cols-2 gap-4">
                    <FormField
                        control={form.control}
                        name="roaster"
                        render={({ field }) => (
                            <FormItem>
                                <FormLabel>Roaster</FormLabel>
                                <FormControl><Input placeholder="The Barn" {...field} /></FormControl>
                                <FormMessage />
                            </FormItem>
                        )}
                    />
                    <FormField
                        control={form.control}
                        name="origin"
                        render={({ field }) => (
                            <FormItem>
                                <FormLabel>Origin</FormLabel>
                                <FormControl><Input placeholder="Ethiopia" {...field} /></FormControl>
                                <FormMessage />
                            </FormItem>
                        )}
                    />
                </div>

                <div className="grid grid-cols-2 gap-4">
                    <FormField
                        control={form.control}
                        name="roastLevel"
                        render={({ field }) => (
                            <FormItem>
                                <FormLabel>Roast Level</FormLabel>
                                <FormControl><Input placeholder="Light" {...field} /></FormControl>
                                <FormMessage />
                            </FormItem>
                        )}
                    />
                    <FormField
                        control={form.control}
                        name="roastDate"
                        render={({ field }) => (
                            <FormItem>
                                <FormLabel>Roast Date</FormLabel>
                                <FormControl><Input type="date" {...field} /></FormControl>
                                <FormMessage />
                            </FormItem>
                        )}
                    />
                </div>

                <div className="grid grid-cols-2 gap-4">
                    <FormField
                        control={form.control}
                        name="process"
                        render={({ field }) => (
                            <FormItem>
                                <FormLabel>Process</FormLabel>
                                <FormControl><Input placeholder="Washed" {...field} /></FormControl>
                                <FormMessage />
                            </FormItem>
                        )}
                    />
                    <FormField
                        control={form.control}
                        name="variety"
                        render={({ field }) => (
                            <FormItem>
                                <FormLabel>Variety</FormLabel>
                                <FormControl><Input placeholder="Geisha" {...field} /></FormControl>
                                <FormMessage />
                            </FormItem>
                        )}
                    />
                </div>

                <FormField
                    control={form.control}
                    name="note"
                    render={({ field }) => (
                        <FormItem>
                            <FormLabel>Note</FormLabel>
                            <FormControl><Textarea placeholder="Tasting notes, etc." {...field} /></FormControl>
                            <FormMessage />
                        </FormItem>
                    )}
                />

                {/* submit button */}
                <Button type="submit" className="w-full" disabled={form.formState.isSubmitting}>
                    {form.formState.isSubmitting ? 'Saving...' : 'Save Bean'}
                </Button>
            </form>
        </Form>
    )
}