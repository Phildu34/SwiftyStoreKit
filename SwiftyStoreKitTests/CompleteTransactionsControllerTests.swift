//
// CompleteTransactionsControllerTests.swift
// SwiftyStoreKit
//
// Copyright (c) 2017 Andrea Bizzotto (bizz84@gmail.com)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import XCTest
import SwiftyStoreKit
import StoreKit

class CompleteTransactionsControllerTests: XCTestCase {

    func testProcessTransactions_when_oneRestoredTransaction_then_finishesTransaction_callsCallback_noRemainingTransactions() {
        
        let productIdentifier = "com.SwiftyStoreKit.product1"
        let testProduct = TestProduct(productIdentifier: productIdentifier)
        
        let transaction = TestPaymentTransaction(payment: SKPayment(product: testProduct), transactionState: .restored)
        
        var callbackCalled = false
        let restorePurchases = CompleteTransactions(atomically: true) { products in
            callbackCalled = true
            XCTAssertEqual(products.count, 1)
            let product = products.first!
            XCTAssertEqual(product.productId, productIdentifier)
        }
        
        let completeTransactionsController = makeCompleteTransactionsController(completeTransactions: restorePurchases)
        
        let spy = PaymentQueueSpy()
        
        let remainingTransactions = completeTransactionsController.processTransactions([transaction], on: spy)
        
        XCTAssertEqual(remainingTransactions.count, 0)
        
        XCTAssertTrue(callbackCalled)
        
        XCTAssertEqual(spy.finishTransactionCalledCount, 1)
    }
    
    func testProcessTransactions_when_oneTransactionForEachState_then_finishesTransactions_callsCallback_onePurchasingTransactionRemaining() {
        
        let transactions = [
            makeTestPaymentTransaction(productIdentifier: "com.SwiftyStoreKit.product1", transactionState: .purchased),
            makeTestPaymentTransaction(productIdentifier: "com.SwiftyStoreKit.product2", transactionState: .failed),
            makeTestPaymentTransaction(productIdentifier: "com.SwiftyStoreKit.product3", transactionState: .restored),
            makeTestPaymentTransaction(productIdentifier: "com.SwiftyStoreKit.product4", transactionState: .deferred),
            makeTestPaymentTransaction(productIdentifier: "com.SwiftyStoreKit.product5", transactionState: .purchasing),
        ]
        
        var callbackCalled = false
        let restorePurchases = CompleteTransactions(atomically: true) { products in
            callbackCalled = true
            XCTAssertEqual(products.count, 4)

            for i in 0..<4 {
                XCTAssertEqual(products[i].productId, transactions[i].payment.productIdentifier)
            }
        }
        
        let completeTransactionsController = makeCompleteTransactionsController(completeTransactions: restorePurchases)
        
        let spy = PaymentQueueSpy()
        
        let remainingTransactions = completeTransactionsController.processTransactions(transactions, on: spy)
        
        XCTAssertEqual(remainingTransactions.count, 1)
        
        XCTAssertTrue(callbackCalled)
        
        XCTAssertEqual(spy.finishTransactionCalledCount, 4)
    }
    
    func makeTestPaymentTransaction(productIdentifier: String, transactionState: SKPaymentTransactionState) -> TestPaymentTransaction {
        
        let testProduct = TestProduct(productIdentifier: productIdentifier)
        return TestPaymentTransaction(payment: SKPayment(product: testProduct), transactionState: transactionState)
    }
    
    func makeCompleteTransactionsController(completeTransactions: CompleteTransactions?) -> CompleteTransactionsController {
        
        let completeTransactionsController = CompleteTransactionsController()
        
        completeTransactionsController.completeTransactions = completeTransactions
        
        return completeTransactionsController
    }

}
