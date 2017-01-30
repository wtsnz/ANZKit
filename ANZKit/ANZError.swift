//
//  ANZError.swift
//  ANZ
//
//  Created by Will Townsend on 29/01/17.
//  Copyright © 2017 Will Townsend. All rights reserved.
//

import Foundation

public struct ANZError: ParsableObject {
    
    public enum Code: String {
        case unknown
        case malformedLoginRequest
        case serverBusy
        case tooManySessions
        case authenticatedButDenied
        case loginDenied
        case invalidPublicKey
        case invalidPublicKeyId
        case authCodeSent
        case authCodeSendFailed
        case noAuthCodeSentMaximumExceeded
        case userMustRegisterForOnlineCodeToContinue
        case invalidAuthCode
        case invalidAuthCodeNoMoreTries
        case invalidAuthCodeNoMoreCodesForAPeriod
        case serverException
        case forbidden
        case accountNumberInvalidFormat
        case badRequest
        case badRequestPreAuth
        case pinNotAllowed
        case pinAlreadyAssigned
        case pinUsedPreviously
        case invalidPin
        case invalidTransferRequest
        case transferRequestFailed
        case fundsTransferInvalidMinDate
        case invalidAccountKeyForPayment
        case missingReferenceDetails
        case invalidCustomerNumberForAccPayment
        case payeeAccountNoIRD
        case paymentAmountMin
        case paymentAmountMax
        case accountCannotTransact
        case paymentFailedCallContactCentre
        case dateAfterCutoff
        case dateInvalid
        case dateTooEarly
        case dateTooLate
        case dateNotBusinessDay
        case accountNoInvalid
        case insufficientFunds
        case systemErrorPaymentNotCreated
        case systemErrorPaymentStateIndeterminate
        case paymentDoneResubmitted
        case tooManyPayees
        case createPayeeNotAllowed
        case systemErrorPayeeNotCreated
        case systemErrorPayeeStateIndeterminate
        case payeeDeleteFailed
        case payeeDeleteError
        case createPaymentNotAllowed
        case fraudPaymentDeclined
        case payeeDeleteNotAllowed
        case deleteUpcomingPaymentFailed
        case deleteUpcomingPaymentFailedAlreadyPaid
        case deleteUpcomingPaymentOutcomeUnknown
        case deleteUpcomingPaymentError
        case errorParsingMobilePhoneNumber
        case invalidAccountForPayToMobile
        case pinResetFailed
        case invalidToken
        case userAlreadyHasASession
        case p2mBankAnywhereResponsePaymentDeclined
        case p2mBankAnywhereResponseInsufficientFunds
        case p2mBankAnywhereResponsePaymentFailed
        case p2mBankAnywhereResponseDailyLimitExceeded
        case maxDevicesExceeded
        case invalidRegisterDeviceRequest
        case authCodeSentNumberInUse
        case invalidPcrDetails
        case notAuthorised
        case E528463
        case E112485
        case E786288
        case E111898
        case E548687
        case newVersionAvailable
        case cantHideCustomer
        case connectivityTimeout
        case connectivityError
        case searchWithNullLocationError
        case quickBalanceTokenMissing
        case quickBalanceNoAccounts
        case qbRateLimit
        case qbThrottlingMessage
        case creditLimitIncreaseFailed
        case creditLimitIncreaseFailedVisionPlusUnavailable
        case creditLimitIncreaseDeclinedDueToNoOfferAvailable
        case creditLimitIncreaseInvalidAmount
        case creditLimitIncreaseInvalidAccount
        case publicKeyForCardPinCouldNotBeAcquired
        case cardPinServiceIsNotAvailable
        case cardsForCardPinFailed
        case cardForCardPinSetFailedInvalidCard
        case pinForCardCouldNotBeSet
        case setCardPinRequestEncryptedPinBlockMandatory = "setCardPinRequest.encryptedPinBlock.mandatory"
        case apEditDateAfterBatchCutoff
        case apEditAmountAboveMax
        case apAmountAboveMax
        case apDateAfterCutoff
        case apAccountsAreTheSame
        case apAccountAccInvalidCustomerNumber
        case apAccountIrd
        case fraudApDeclined
        case systemUnavailable
        case systemMaintenance
        case unknownContent
        case foreignCurrencyQuoteRequestFailedSystemUnavailable
        case foreignCurrencyQuoteRequestFailedSystemError
        case foreignCurrencyQuoteRequestFailedInvalidCurrencyPair
        case foreignCurrencyQuoteRequestFailedExceedsInHoursLimit
        case foreignCurrencyQuoteRequestFailedExceedsLimitOutOfHours
        case foreignCurrencyTransferFailedSystemUnavailable
        case foreignCurrencyTransferFailedSystemError
        case foreignCurrencyTransferFailedQuoteExpired
        case foreignCurrencyTransferFailedInsufficientFunds
        case foreignCurrencyTransferFailedInvalidCurrencyPair
        case fundsTransferInvalidFromTo
        case foreignCurrencyTransferFailedExceedsInHoursLimit
        case foreignCurrencyTransferFailedExceedsLimitOutOfHours
        case documentDownloadInvalidKey
        case documentDownloadNoKey
        case documentDownloadStreamingError
        case documentDownloadSystemError
        case documentSearchInvalid
        case documentSearchInvalidAccount
        case documentSearchInvalidCustomer
        case documentSearchInvalidDateRange
        case documentSearchInvalidContentReturned
        case documentSearchSystemError
        case wisRequestError
        case wisAddCardHostFail
        case wisRequestFailedTryAgain
        case tpAmountAboveLimit
        case tpHostDown
        case tpMandatesDown
        case tpUnknownHostFailure
        case alertsInvalidEmailAddress
        case deviceSecuredSecretDisabled
    }
    
    // httpStatus
    // serverDateTime
    
    public let code: Code
    public let devDescription: String?
    public let sinceVersion: Int?
    public let httpStatus: Int?
    
    public init?(jsonDictionary: [String: Any]) {
        
        let parser = Parser(dictionary: jsonDictionary)
        
        do {
            self.code = try parser.fetch("code") { Code(rawValue: $0) }
            self.devDescription = try parser.fetchOptional("devDescription")
            self.sinceVersion = try parser.fetchOptional("sinceVersion")
            self.httpStatus = try parser.fetchOptional("httpStatus")
            
        } catch let error {
            print(error)
            return nil
        }
    }
}
