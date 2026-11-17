import Flutter
import StoreKit

/// Apple-signed StoreKit transactions are the source of truth; no paid flag in preferences.
@MainActor
final class StorePurchases {
  private static let productID = "dokoshado_unlimited"
  private let channel: FlutterMethodChannel
  private var product: Product?
  private var unlimited = false
  private var busy = false
  private var pending = false
  private var message: String?
  private var updates: Task<Void, Never>?

  init(channel: FlutterMethodChannel) {
    self.channel = channel
    channel.setMethodCallHandler { [weak self] call, result in
      Task { @MainActor [weak self] in
        guard let self else { result(FlutterError(code: "unavailable", message: "購入処理を利用できません。", details: nil)); return }
        guard ["refresh", "buy", "restore"].contains(call.method) else {
          result(FlutterMethodNotImplemented)
          return
        }
        guard !self.busy else { result(self.snapshot()); return }
        self.busy = true
        self.message = nil
        self.emit()
        do {
          switch call.method {
          case "buy": try await self.buy()
          case "restore":
            // Only an explicit user action may trigger a sign-in prompt.
            try await AppStore.sync()
            await self.loadEntitlements()
            try await self.loadProduct()
            self.message = self.unlimited ? "購入を復元しました。" : "復元できる購入はありませんでした。"
          default:
            await self.loadEntitlements()
            try await self.loadProduct()
          }
        } catch {
          self.message = "App Storeで購入情報を確認できませんでした。時間をおいて再度お試しください。"
        }
        self.busy = false
        self.emit()
        result(self.snapshot())
      }
    }
    updates = Task { @MainActor [weak self] in
      for await update in Transaction.updates {
        guard !Task.isCancelled, let self else { return }
        guard case .verified(let transaction) = update,
              transaction.productID == Self.productID else { continue }
        await self.loadEntitlements()
        self.pending = false
        self.emit()
        await transaction.finish()
      }
    }
  }

  deinit { updates?.cancel() }

  private func loadProduct() async throws {
    product = try await Product.products(for: [Self.productID])
      .first(where: { $0.id == Self.productID && $0.type == .nonConsumable })
    if product == nil {
      message = "現在、この商品を購入できません。時間をおいて再度お試しください。"
    }
  }

  private func loadEntitlements() async {
    var owned = false
    for await entitlement in Transaction.currentEntitlements {
      if case .verified(let transaction) = entitlement,
         transaction.productID == Self.productID,
         transaction.productType == .nonConsumable,
         transaction.revocationDate == nil {
        owned = true
      }
    }
    unlimited = owned
    if owned { pending = false }
  }

  private func buy() async throws {
    if product == nil { try await loadProduct() }
    guard let product else { return }
    switch try await product.purchase() {
    case .success(let verification):
      guard case .verified(let transaction) = verification,
            transaction.productID == Self.productID,
            transaction.productType == .nonConsumable,
            transaction.revocationDate == nil else {
        message = "購入の確認が完了していません。購入を復元するか、時間をおいて再度お試しください。"
        return
      }
      unlimited = true
      pending = false
      message = "無制限プランが有効になりました。"
      emit()
      await transaction.finish()
    case .pending:
      pending = true
      message = "お支払いの確認後に、無制限プランが有効になります。"
    case .userCancelled:
      pending = false
      message = "購入をキャンセルしました。"
    @unknown default:
      message = "購入の状態を確認できませんでした。購入を復元して確認してください。"
    }
  }

  private func snapshot() -> [String: Any] {
    var value: [String: Any] = [
      "unlimited": unlimited, "ready": product != nil,
      "busy": busy, "pending": pending,
    ]
    if let product { value["price"] = product.displayPrice }
    if let message { value["message"] = message }
    return value
  }

  private func emit() { channel.invokeMethod("changed", arguments: snapshot()) }
}
