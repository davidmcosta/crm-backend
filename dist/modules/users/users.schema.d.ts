import { z } from 'zod';
export declare const createUserSchema: z.ZodObject<{
    name: z.ZodString;
    email: z.ZodString;
    username: z.ZodOptional<z.ZodString>;
    password: z.ZodString;
    role: z.ZodDefault<z.ZodNativeEnum<any>>;
}, "strip", z.ZodTypeAny, {
    [x: string]: any;
    name?: unknown;
    email?: unknown;
    username?: unknown;
    password?: unknown;
    role?: unknown;
}, {
    [x: string]: any;
    name?: unknown;
    email?: unknown;
    username?: unknown;
    password?: unknown;
    role?: unknown;
}>;
export declare const updateUserSchema: z.ZodObject<{
    name: z.ZodOptional<z.ZodString>;
    email: z.ZodOptional<z.ZodString>;
    username: z.ZodOptional<z.ZodString>;
}, "strip", z.ZodTypeAny, {
    username?: string | undefined;
    email?: string | undefined;
    name?: string | undefined;
}, {
    username?: string | undefined;
    email?: string | undefined;
    name?: string | undefined;
}>;
export declare const updateRoleSchema: z.ZodObject<{
    role: z.ZodNativeEnum<any>;
}, "strip", z.ZodTypeAny, {
    [x: string]: any;
    role?: unknown;
}, {
    [x: string]: any;
    role?: unknown;
}>;
export declare const changePasswordSchema: z.ZodObject<{
    currentPassword: z.ZodString;
    newPassword: z.ZodString;
}, "strip", z.ZodTypeAny, {
    currentPassword: string;
    newPassword: string;
}, {
    currentPassword: string;
    newPassword: string;
}>;
export type CreateUserInput = z.infer<typeof createUserSchema>;
export type UpdateUserInput = z.infer<typeof updateUserSchema>;
export type UpdateRoleInput = z.infer<typeof updateRoleSchema>;
export type ChangePasswordInput = z.infer<typeof changePasswordSchema>;
//# sourceMappingURL=users.schema.d.ts.map