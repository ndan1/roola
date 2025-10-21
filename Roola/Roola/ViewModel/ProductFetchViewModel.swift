//
//  ProductFetchViewModel.swift
//  Roola
//

import SwiftUI
import SwiftData

@MainActor
class ProductFetchViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var fetchedClothes: Clothes?
    
    // MARK: - Private Properties
    private let supabaseService: SupabaseService
    
    // MARK: - Initialization
    init(supabaseService: SupabaseService = SupabaseService()) {
        self.supabaseService = supabaseService
    }
    
    // MARK: - Public Methods
    func fetchProductFromShortURL(_ shortURL: String) async {
        guard !shortURL.isEmpty else {
            errorMessage = "URL tidak boleh kosong"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await supabaseService.getProductDataFromShortURL(shortURL)

            self.fetchedClothes = convertToClothesModel(response)
            
        } catch let error as NetworkError {
            handleNetworkError(error)
        } catch {
            errorMessage = "Terjadi kesalahan: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Fetch product langsung dengan shop_id dan product_id
    func fetchProduct(shopId: String, productId: String) async {
        guard !shopId.isEmpty && !productId.isEmpty else {
            errorMessage = "Shop ID dan Product ID tidak boleh kosong"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await supabaseService.getProductData(
                shopId: shopId,
                productId: productId
            )
            self.fetchedClothes = convertToClothesModel(response)
            
        } catch let error as NetworkError {
            handleNetworkError(error)
        } catch {
            errorMessage = "Terjadi kesalahan: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func reset() {
        isLoading = false
        errorMessage = nil
        fetchedClothes = nil
    }
    
    // MARK: - Private Methods
    
    private func convertToClothesModel(_ response: ClothesResponse) -> Clothes {
        let variants = response.product_sizes.map { variantResponse -> Variant in
            Variant(
                size_name: variantResponse.size_name,
                clothes_torso_min: Int(variantResponse.clothes_torso_min ?? 0),
                clothes_torso_max: Int(variantResponse.clothes_torso_max ?? 0),
                clothes_bust_min: Int(variantResponse.clothes_bust_min ?? 0),
                clothes_bust_max: Int(variantResponse.clothes_bust_max ?? 0),
                clothes_arm_length_min: variantResponse.clothes_arm_length_min.map(Int.init),
                clothes_arm_length_max: variantResponse.clothes_arm_length_max.map(Int.init),
                clothes_waist_min: variantResponse.clothes_waist_min.map(Int.init),
                clothes_waist_max: variantResponse.clothes_waist_max.map(Int.init),
                error_tolerance: variantResponse.error_tolerance.map(Int.init)
            )
        }
        
        return Clothes(
            product_id: response.product_id,
            product_name: response.product_name,
            product_type: response.product_type,
            product_sizes: variants
        )
    }
    
    private func handleNetworkError(_ error: NetworkError) {
        switch error {
        case .invalidURL:
            errorMessage = "Format URL tidak valid"
        case .productNotFound:
            errorMessage = "Produk tidak ditemukan di database"
        case .decodingError(let detail):
            errorMessage = "Gagal membaca data produk: \(detail)"
        case .redirectError:
            errorMessage = "Gagal mengikuti redirect URL"
        case .databaseError(let message):
            errorMessage = "Database error: \(message)"
        }
    }
}
