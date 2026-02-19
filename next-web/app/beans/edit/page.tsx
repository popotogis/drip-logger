'use client'

import { useEffect, useState, Suspense } from 'react'
import { useRouter, useSearchParams } from 'next/navigation'
import { auth } from '@/lib/firebase'
import { useAuthState } from 'react-firebase-hooks/auth'
import { getBean, updateBean } from '@/lib/beanUtils'
import { BeanForm } from '@/components/ui/bean-form'
import { Bean } from '@/types/bean'
import { Button } from '@/components/ui/button'
import { ArrowLeft } from 'lucide-react'
import Link from 'next/link'

function EditBeanContent() {
    const searchParams = useSearchParams()
    const id = searchParams.get('id')
    const [user, loading] = useAuthState(auth)
    const [bean, setBean] = useState<Bean | null>(null)
    const router = useRouter()

    useEffect(() => {
        if (user && id) {
            getBean(user.uid, id).then(setBean)
        }
    }, [user, id])

    const handleSubmit = async (data: any) => {
        if (!user || !bean) return
        try {
            await updateBean(user.uid, { ...bean, ...data })
            router.push('/beans')
        } catch (error) {
            console.error(error)
            alert('Failed to update bean')
        }
    }

    if (loading || !bean) return <div className="p-8">Loading...</div>

    return (
        <div className="container mx-auto py-10 px-4 max-w-2xl">
            <Link href="/beans" className="mb-6 inline-block">
                <Button variant="ghost" className="pl-0">
                    <ArrowLeft className="mr-2 h-4 w-4" />
                    Back
                </Button>
            </Link>

            <h1 className="text-3xl font-bold mb-8">Edit Bean</h1>

            <div className="bg-white p-6 rounded-lg shadow-sm border">
                <BeanForm defaultValues={bean} onSubmit={handleSubmit} />
            </div>
        </div>
    )
}

export default function EditBeanPage() {
    return (
        <Suspense fallback={<div>Loading...</div>}>
            <EditBeanContent />
        </Suspense>
    )
}