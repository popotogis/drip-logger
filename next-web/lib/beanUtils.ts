import { db } from '@/lib/firebase'
import { Bean } from '@/types/bean'
import {
    collection,
    doc,
    setDoc,
    getDoc,
    getDocs,
    deleteDoc,
    query,
    orderBy,
    FirestoreDataConverter,
    serverTimestamp
} from 'firebase/firestore'

const beanConverter: FirestoreDataConverter<Bean> = {
    toFirestore(bean: Bean) {
        return {
            ...bean,
            updatedAt: serverTimestamp()
        }
    },
    fromFirestore(snapshot, options) {
        const data = snapshot.data(options)
        return {
            id: snapshot.id,
            ...data,
        } as Bean
    }
}

export async function createBean(uid: string, beanData: Omit<Bean, 'id'>): Promise<string> {
    const colRef = collection(db, 'users', uid, 'beans').withConverter(beanConverter)
    const docRef = doc(colRef)
    const newBean: Bean = {
        ...beanData,
        id: docRef.id,
        createdAt: serverTimestamp() as any
    }
    await setDoc(docRef, newBean)
    return docRef.id
}

export async function updateBean(uid: string, bean: Bean): Promise<void> {
    const docRef = doc(db, 'users', uid, 'beans', bean.id).withConverter(beanConverter)
    const { id, createdAt, ...updateData } = bean
    await setDoc(docRef, updateData as any, { merge: true })
}

export async function getBeans(uid: string): Promise<Bean[]> {
    const colRef = collection(db, 'users', uid, 'beans').withConverter(beanConverter)
    const q = query(colRef, orderBy('createdAt', 'desc'))
    const snap = await getDocs(q)
    return snap.docs.map(doc => doc.data())
}

export async function getBean(uid: string, beanId: string): Promise<Bean | null> {
    const docRef = doc(db, 'users', uid, 'beans', beanId).withConverter(beanConverter)
    const snap = await getDoc(docRef)
    return snap.exists() ? snap.data() : null
}

export async function deleteBean(uid: string, beanId: string): Promise<void> {
    const docRef = doc(db, 'users', uid, 'beans', beanId)
    await deleteDoc(docRef)
}