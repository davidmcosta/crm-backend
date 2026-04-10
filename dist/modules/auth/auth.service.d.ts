import { FastifyInstance } from 'fastify';
import { LoginInput } from './auth.schema';
export declare function loginService(app: FastifyInstance, data: LoginInput): Promise<{
    accessToken: string;
    refreshToken: string;
    user: {
        id: any;
        name: any;
        email: any;
        role: any;
    };
}>;
export declare function refreshTokenService(app: FastifyInstance, refreshToken: string): Promise<{
    accessToken: string;
}>;
//# sourceMappingURL=auth.service.d.ts.map