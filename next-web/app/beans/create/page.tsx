'use client'

import { useRouter } from 'next/navigation'
import { auth } from '@/lib/firebase'
import { useAuthState } from 'react-firebase-hooks/auth'
import { createBean } from '@/lib/beanUtils'
import { BeanForm } from '@/components/ui/bean-form'
import { Button } from '@/components/ui/button'
import { ArrowLeft } from 'lucide-react'
import Link from 'next/link'

export default function CreateBeanPage() {
    const [user, loading] = useAuthState(auth)
    const router = useRouter()

    const handleSubmit = async (data: any) => {
        if (!user) return
        try {
            await createBean(user.uid, data)
            router.push('/beans')
        } catch (e) {
            console.error(e)
            alert('Failed to create bean')
        }
    }

    if (loading) return <div className="p-8">Loading...</div>
    if (!user) return <div className="p-8">Please sign in.</div>

    return (
        <div className="container mx-auto py-10 px-4 max-w-2xl">
            <Link href="/beans" className="mb-6 inline-block">
                <Button variant="ghost" className="pl-0">
                    <ArrowLeft className="mr-2 h-4 w-4" />
                    Back
                </Button>
            </Link>

            <h1 className="text-3xl font-bold mb-8">Add New Bean</h1>

            <div className="bg-white p-6 rounded-lg shadow-sm border">
                <BeanForm onSubmit={handleSubmit} />
            </div>
        </div>
    )
}