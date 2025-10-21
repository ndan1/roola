//
//  SupabaseService.swift
//  Roola
//

import Foundation
import Supabase

enum NetworkError: Error {
    case invalidURL
    case productNotFound
    case decodingError(String)
    case redirectError
    case databaseError(String)
}

class SupabaseService {
    
    private let client: SupabaseClient
    
    init(client: SupabaseClient = supabase) {
        self.client = client
    }
    
    // MARK: - Test Connection
    func testConnection() async throws -> Bool {
        do {
            let _: [TestQuery] = try await client
                .from("products")
                .select("product_id")
                .limit(1)
                .execute()
                .value
            
            print("✅ Supabase connection successful")
            return true
        } catch {
            print("❌ Supabase connection failed: \(error)")
            throw error
        }
    }
    
    // MARK: - URL Resolution
    func resolveShortURLWithDelegate(_ shortURL: String) async throws -> (shopId: String, productId: String) {
        guard let url = URL(string: shortURL) else {
            throw NetworkError.invalidURL
        }
        
        print("🔍 Resolving short URL: \(shortURL)")
        
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<(shopId: String, productId: String), Error>) in
            let redirectFollower = RedirectFollower { result in
                continuation.resume(with: result)
            }
            redirectFollower.followRedirect(from: url)
        }
    }
    
    // MARK: - Helper Methods
    private func extractIDs(from urlString: String) throws -> (shopId: String, productId: String) {
        print("🔍 Extracting IDs from URL: \(urlString)")
        
        let pattern = #"/product/(\d+)/(\d+)"#
        let regex = try NSRegularExpression(pattern: pattern)
        let nsString = urlString as NSString
        let range = NSRange(location: 0, length: nsString.length)
        
        guard let match = regex.firstMatch(in: urlString, range: range),
              match.numberOfRanges == 3 else {
            print("❌ Failed to extract IDs from URL")
            throw NetworkError.invalidURL
        }
        
        let shopId = nsString.substring(with: match.range(at: 1))
        let productId = nsString.substring(with: match.range(at: 2))
        
        print("✅ Extracted - Shop ID: \(shopId), Product ID: \(productId)")
        
        return (shopId: shopId, productId: productId)
    }
    
    // MARK: - Data Fetching
    func getProductData(shopId: String, productId: String) async throws -> ClothesResponse {
        
        print("🔍 Fetching product - Shop ID: \(shopId), Product ID: \(productId)")
        
        do {
            let response: [ProductQueryResult] = try await client
                .from("products")
                .select("""
                    product_id,
                    shopee_product_id,
                    shop_id,
                    clothing_types!inner(type_name),
                    materials!inner(material_name),
                    product_variants!inner(
                        variant_id,
                        sizes!inner(size_name),
                        products_variant_top(*),
                        products_variant_bottom(*)
                    )
                """)
                .eq("shop_id", value: shopId)
                .eq("shopee_product_id", value: productId)
                .execute()
                .value
            
            print("✅ Query successful, found \(response.count) products")
            
            guard let product = response.first else {
                print("❌ Product not found in database")
                throw NetworkError.productNotFound
            }
            
            print("✅ Converting product to ClothesResponse")
            
            return convertToClothesResponse(product)
            
        } catch let error as PostgrestError {
            print("❌ Database error: \(error.message)")
            throw NetworkError.databaseError(error.message)
        } catch let error as DecodingError {
            print("❌ Decoding error: \(error)")
            throw NetworkError.decodingError(error.localizedDescription)
        } catch {
            print("❌ Unknown error: \(error)")
            throw NetworkError.decodingError(error.localizedDescription)
        }
    }
    
    func getProductDataFromShortURL(_ shortURL: String) async throws -> ClothesResponse {
        let ids = try await resolveShortURLWithDelegate(shortURL)
        return try await getProductData(shopId: ids.shopId, productId: ids.productId)
    }
    
    private func convertToClothesResponse(_ product: ProductQueryResult) -> ClothesResponse {
        let variants = product.product_variants.map { variant -> VariantResponse in
            if let top = variant.products_variant_top {
                return VariantResponse(
                    size_name: variant.sizes.size_name,
                    clothes_torso_min: Double(top.clothes_torso_min),
                    clothes_torso_max: Double(top.clothes_torso_max),
                    clothes_bust_min: Double(top.clothes_bust_min),
                    clothes_bust_max: Double(top.clothes_bust_max),
                    clothes_arm_length_min: top.clothes_arm_length_min.map(Double.init),
                    clothes_arm_length_max: top.clothes_arm_length_max.map(Double.init),
                    clothes_waist_min: top.clothes_waist_min.map(Double.init),
                    clothes_waist_max: top.clothes_waist_max.map(Double.init),
                    clothes_hips_min: nil,
                    clothes_hips_max: nil,
                    clothes_inbeam_min: nil,
                    clothes_inbeam_max: nil,
                    error_tolerance: top.error_tolerance
                )
            } else if let bottom = variant.products_variant_bottom {
                return VariantResponse(
                    size_name: variant.sizes.size_name,
                    clothes_torso_min: nil,
                    clothes_torso_max: nil,
                    clothes_bust_min: nil,
                    clothes_bust_max: nil,
                    clothes_arm_length_min: nil,
                    clothes_arm_length_max: nil,
                    clothes_waist_min: Double(bottom.clothes_waist_min),
                    clothes_waist_max: Double(bottom.clothes_waist_max),
                    clothes_hips_min: Double(bottom.clothes_hips_min),
                    clothes_hips_max: Double(bottom.clothes_hips_max),
                    clothes_inbeam_min: Double(bottom.clothes_inbeam_min),
                    clothes_inbeam_max: Double(bottom.clothes_inbeam_max),
                    error_tolerance: bottom.error_tolerance
                )
            } else {
                return VariantResponse(
                    size_name: variant.sizes.size_name,
                    clothes_torso_min: nil,
                    clothes_torso_max: nil,
                    clothes_bust_min: nil,
                    clothes_bust_max: nil,
                    clothes_arm_length_min: nil,
                    clothes_arm_length_max: nil,
                    clothes_waist_min: nil,
                    clothes_waist_max: nil,
                    clothes_hips_min: nil,
                    clothes_hips_max: nil,
                    clothes_inbeam_min: nil,
                    clothes_inbeam_max: nil,
                    error_tolerance: nil
                )
            }
        }
        
        print("✅ Successfully converted \(variants.count) variants")
        
        return ClothesResponse(
            product_id: product.product_id,
            product_name: product.clothing_types.type_name,
            product_type: product.clothing_types.type_name,
            product_sizes: variants
        )
    }

    
    // MARK: - Nested Types
    private struct TestQuery: Codable {
        let product_id: String
    }
}

// MARK: - Helper class untuk follow redirect
private class RedirectFollower: NSObject, URLSessionTaskDelegate {
    private var completion: (Result<(shopId: String, productId: String), Error>) -> Void
    
    init(completion: @escaping (Result<(shopId: String, productId: String), Error>) -> Void) {
        self.completion = completion
        super.init()
    }
    
    func followRedirect(from url: URL) {
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        let task = session.dataTask(with: url)
        task.resume()
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        if let finalURL = request.url?.absoluteString {
            print("✅ Redirected to: \(finalURL)")
            
            do {
                let pattern = #"/product/(\d+)/(\d+)"#
                let regex = try NSRegularExpression(pattern: pattern)
                let nsString = finalURL as NSString
                let range = NSRange(location: 0, length: nsString.length)
                
                if let match = regex.firstMatch(in: finalURL, range: range),
                   match.numberOfRanges == 3 {
                    let shopId = nsString.substring(with: match.range(at: 1))
                    let productId = nsString.substring(with: match.range(at: 2))
                    print("✅ Extracted IDs - Shop: \(shopId), Product: \(productId)")
                    completion(.success((shopId: shopId, productId: productId)))
                } else {
                    print("❌ Failed to extract IDs from redirect URL")
                    completion(.failure(NetworkError.invalidURL))
                }
            } catch {
                print("❌ Regex error: \(error)")
                completion(.failure(NetworkError.invalidURL))
            }
        }
        
        completionHandler(nil)
        session.invalidateAndCancel()
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error, error._code != NSURLErrorCancelled {
            print("❌ URLSession error: \(error)")
            completion(.failure(error))
        }
    }
}

// MARK: - Query Result Models
struct ProductQueryResult: Codable {
    let product_id: String
    let shopee_product_id: String
    let shop_id: String
    let clothing_types: ClothingType
    let materials: Material
    let product_variants: [ProductVariant]
    
    struct ClothingType: Codable {
        let type_name: String
    }
    
    struct Material: Codable {
        let material_name: String
    }
    
    struct ProductVariant: Codable {
        let variant_id: String
        let sizes: Size
        let products_variant_top: ProductVariantTop?
        let products_variant_bottom: ProductVariantBottom?
        
        struct Size: Codable {
            let size_name: String
        }
        
        struct ProductVariantTop: Codable {
            let clothes_torso_min: Int
            let clothes_torso_max: Int
            let clothes_bust_min: Int
            let clothes_bust_max: Int
            let clothes_arm_length_min: Int?
            let clothes_arm_length_max: Int?
            let clothes_waist_min: Int?
            let clothes_waist_max: Int?
            let error_tolerance: Double
        }
        
        struct ProductVariantBottom: Codable {
            let clothes_waist_min: Int
            let clothes_waist_max: Int
            let clothes_hips_min: Int
            let clothes_hips_max: Int
            let clothes_inbeam_min: Int
            let clothes_inbeam_max: Int
            let error_tolerance: Double
        }
    }
}


