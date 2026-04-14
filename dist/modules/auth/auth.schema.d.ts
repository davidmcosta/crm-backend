import { z } from 'zod';
export declare const loginSchema: z.ZodObject<{
    login: z.ZodString;
    password: z.ZodString;
}, "strip", z.ZodTypeAny, {
    login: string;
    password: string;
}, {
    login: string;
    password: string;
}>;
export declare const refreshSchema: z.ZodObject<{
    refreshToken: z.ZodString;
}, "strip", z.ZodTypeAny, {
    refreshToken: string;
}, {
    refreshToken: string;
}>;
export type LoginInput = z.infer<typeof loginSchema>;
export type RefreshInput = z.infer<typeof refreshSchema>;
//# sourceMappingURL=auth.schema.d.ts.map