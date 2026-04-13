import { CreateProductInput, UpdateProductInput, ListProductsQuery } from './products.schema';
export declare function listProducts(query: ListProductsQuery): Promise<any>;
export declare function getProductById(id: string): Promise<any>;
export declare function createProduct(data: CreateProductInput): Promise<any>;
export declare function updateProduct(id: string, data: UpdateProductInput): Promise<any>;
export declare function deleteProduct(id: string): Promise<{
    success: boolean;
}>;
export declare function listCategories(): Promise<any>;
//# sourceMappingURL=products.service.d.ts.map