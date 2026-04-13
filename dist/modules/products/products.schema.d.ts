import { z } from 'zod';
export declare const createProductSchema: z.ZodObject<{
    name: z.ZodString;
    category: z.ZodOptional<z.ZodString>;
    description: z.ZodOptional<z.ZodString>;
    basePrice: z.ZodDefault<z.ZodNumber>;
    isActive: z.ZodDefault<z.ZodBoolean>;
    bomItems: z.ZodDefault<z.ZodArray<z.ZodObject<{
        componentName: z.ZodString;
        qty: z.ZodDefault<z.ZodNumber>;
        includedPrice: z.ZodDefault<z.ZodNumber>;
        sortOrder: z.ZodDefault<z.ZodNumber>;
    }, "strip", z.ZodTypeAny, {
        qty: number;
        componentName: string;
        includedPrice: number;
        sortOrder: number;
    }, {
        componentName: string;
        qty?: number | undefined;
        includedPrice?: number | undefined;
        sortOrder?: number | undefined;
    }>, "many">>;
}, "strip", z.ZodTypeAny, {
    name: string;
    basePrice: number;
    isActive: boolean;
    bomItems: {
        qty: number;
        componentName: string;
        includedPrice: number;
        sortOrder: number;
    }[];
    category?: string | undefined;
    description?: string | undefined;
}, {
    name: string;
    category?: string | undefined;
    description?: string | undefined;
    basePrice?: number | undefined;
    isActive?: boolean | undefined;
    bomItems?: {
        componentName: string;
        qty?: number | undefined;
        includedPrice?: number | undefined;
        sortOrder?: number | undefined;
    }[] | undefined;
}>;
export declare const updateProductSchema: z.ZodObject<{
    name: z.ZodOptional<z.ZodString>;
    category: z.ZodOptional<z.ZodOptional<z.ZodString>>;
    description: z.ZodOptional<z.ZodOptional<z.ZodString>>;
    basePrice: z.ZodOptional<z.ZodDefault<z.ZodNumber>>;
    isActive: z.ZodOptional<z.ZodDefault<z.ZodBoolean>>;
    bomItems: z.ZodOptional<z.ZodDefault<z.ZodArray<z.ZodObject<{
        componentName: z.ZodString;
        qty: z.ZodDefault<z.ZodNumber>;
        includedPrice: z.ZodDefault<z.ZodNumber>;
        sortOrder: z.ZodDefault<z.ZodNumber>;
    }, "strip", z.ZodTypeAny, {
        qty: number;
        componentName: string;
        includedPrice: number;
        sortOrder: number;
    }, {
        componentName: string;
        qty?: number | undefined;
        includedPrice?: number | undefined;
        sortOrder?: number | undefined;
    }>, "many">>>;
}, "strip", z.ZodTypeAny, {
    name?: string | undefined;
    category?: string | undefined;
    description?: string | undefined;
    basePrice?: number | undefined;
    isActive?: boolean | undefined;
    bomItems?: {
        qty: number;
        componentName: string;
        includedPrice: number;
        sortOrder: number;
    }[] | undefined;
}, {
    name?: string | undefined;
    category?: string | undefined;
    description?: string | undefined;
    basePrice?: number | undefined;
    isActive?: boolean | undefined;
    bomItems?: {
        componentName: string;
        qty?: number | undefined;
        includedPrice?: number | undefined;
        sortOrder?: number | undefined;
    }[] | undefined;
}>;
export declare const listProductsQuerySchema: z.ZodObject<{
    category: z.ZodOptional<z.ZodString>;
    search: z.ZodOptional<z.ZodString>;
    active: z.ZodOptional<z.ZodEnum<["true", "false"]>>;
}, "strip", z.ZodTypeAny, {
    search?: string | undefined;
    category?: string | undefined;
    active?: "true" | "false" | undefined;
}, {
    search?: string | undefined;
    category?: string | undefined;
    active?: "true" | "false" | undefined;
}>;
export type CreateProductInput = z.infer<typeof createProductSchema>;
export type UpdateProductInput = z.infer<typeof updateProductSchema>;
export type ListProductsQuery = z.infer<typeof listProductsQuerySchema>;
//# sourceMappingURL=products.schema.d.ts.map