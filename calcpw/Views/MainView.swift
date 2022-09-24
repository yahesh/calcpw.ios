//
// MainView.swift
// calc.pw
//
// Copyright (c) 2022, Yahe
// All rights reserved.
//

import CommonCrypto
import SwiftUI
import UniformTypeIdentifiers

struct MainView : View {

    // ===== PRIVATE CONSTANTS =====

    // this defines the timeout to lock the application
    public static let LOCK_TIMEOUT : TimeInterval = 60;

    // this defines the grouping of the displayed password
    private static let PASSWORD_GROUPS_LENGTH   : Int = 8
    private static let PASSWORD_GROUPS_PER_LINE : Int = 3

    // this defines the QR code correction level,
    // we select a low-percentage error correction as we will display the QR code on a
    // high-resolution screen which will produce virtually no errors while reading it
    //
    // the available correction levels are:
    // "L" - Low-percentage error correction: 20% of the symbol data is dedicated to error correction.
    // "M" - Medium-percentage error correction: 37% of the symbol data is dedicated to error correction.
    // "Q" - High-percentage error correction: 55% of the symbol data is dedicated to error correction.
    // "H" - Very-high-percentage error correction: 65% of the symbol data is dedicated to error correction.
    private static let QR_CODE_CORRECTION_LEVEL : String = "L"

    // ===== PRIVATE VARIABLES =====

    // let us find out if we should hide the app content
    @Environment(\.redactionReasons) private var environmentRedactionReasons : RedactionReasons

    // define our state
    @State private var stateCalculatedPassword    : String       = ""
    @State private var stateCalculationSuccess    : Bool         = false
    @State private var stateCharacterset          : String       = calcpwApp.appstorageCharacterset
    @State private var stateEnforce               : Bool         = calcpwApp.appstorageEnforce
    @State private var stateInformation           : String       = ""
    @State private var stateLength                : String       = calcpwApp.appstorageLength
    @State private var statePassword1             : String       = ""
    @State private var statePassword2             : String       = ""
    @State private var stateShowConfiguration     : Bool         = false
    @State private var stateShowCopiedToClipboard : Bool         = false
    @State private var stateShowPassword          : Bool         = false
    @State private var stateShowQRCode            : Bool         = false
    @State private var stateShowSavedAsDefault    : Bool         = false
    @State private var stateUnlocked              : Bool         = false
    @State private var stateUnlockedOnce          : Bool         = false
    @State private var stateUnlockedTimestamp     : TimeInterval = 0

    init(
        _ unlocked : Bool
    ) {
        _stateUnlocked = State(initialValue : unlocked)
    }

    // ===== PRIVATE FUNCTIONS =====

    // handle the calculate-password button click
    private func calculateButtonClicked() {
        if (isMainViewFormFilledOut()) {
            withAnimation(.linear) {
                // clear previous password display
                stateCalculatedPassword = ""
                stateCalculationSuccess = false
                stateShowPassword       = false
                stateShowQRCode         = false

                // calculate the password
                stateCalculatedPassword = CalcPW.calcpw(statePassword1, statePassword2, stateInformation, stateLength, stateCharacterset, stateEnforce, $stateCalculationSuccess)
                if (stateCalculationSuccess) {
                    // reset configuration
                    stateCharacterset = calcpwApp.appstorageCharacterset
                    stateEnforce      = calcpwApp.appstorageEnforce
                    stateInformation  = ""
                    stateLength       = calcpwApp.appstorageLength
                }
            }
        }
    }

    // handle the configuration button click
    private func configurationButtonClicked() {
        withAnimation(.linear) {
            stateShowConfiguration.toggle()
        }
    }

    // handle the copy-to-clipboard button click
    private func copyToClipboardButtonClicked() {
        if (stateCalculationSuccess) {
            // copy the password to the local clipboard
            UIPasteboard.general.setItems([[UTType.utf8PlainText.identifier : stateCalculatedPassword]], options : [.localOnly : true])

            // show an info about it
            withAnimation(.linear) {
                stateShowCopiedToClipboard = true
            }
        }
    }

    // check if all form values are set so that the password can be calculated
    private func isMainViewFormFilledOut(
    ) -> Bool {
        return ((0 < statePassword1.count)     &&
                (0 < statePassword2.count)     &&
                (0 < stateInformation.count)   &&
                (0 < stateLength.count)        &&
                (0 < stateCharacterset.count))
    }

    // check if the configuration is different from the stored default
    private func isConfigurationModified(
    ) -> Bool {
        return ((stateCharacterset != calcpwApp.appstorageCharacterset) ||
                (stateEnforce      != calcpwApp.appstorageEnforce)      ||
                (stateLength       != calcpwApp.appstorageLength))
    }

    // handle MainView appear
    private func mainViewAppeared() {
        // when we are unlocked and started the application lock timeout
        // before then let's check if we reached the lock timeout
        if (stateUnlocked && (0 != stateUnlockedTimestamp)) {
            // when the lock timeout is reached we lock the application
            if (MainView.LOCK_TIMEOUT < (Date().timeIntervalSince1970 - stateUnlockedTimestamp)) {
                stateUnlocked     = false
                stateUnlockedOnce = false
            }
        }

        // reset the lock timeout in all cases
        stateUnlockedTimestamp = 0
    }

    // handle MailView disappear
    private func mainViewDisappeared() {
        // when we are unlocked and exit the view then let's start
        // the timeout until the application gets locked
        if (stateUnlocked) {
            stateUnlockedTimestamp = Date().timeIntervalSince1970
        }
    }

    // handle MainView-Form click
    private func mainViewFormClicked() {
        UIApplication.shared.hideKeyboard()
    }

    // handle save-as-default button click
    private func saveAsDefaultButtonClicked() {
        if (isConfigurationModified()) {
            // store default values
            calcpwApp.appstorageCharacterset = stateCharacterset
            calcpwApp.appstorageEnforce      = stateEnforce
            calcpwApp.appstorageLength       = stateLength

            // show an info about it
            withAnimation(.linear) {
                stateShowSavedAsDefault = true
            }
        }
    }

    // handle show-password button click
    private func showPasswordButtonClicked() {
        stateShowPassword.toggle()
    }

    // handle show-qrcode button click
    private func showQRCodeButtonClicked() {
        stateShowQRCode = true
    }

    // this splits a string into groups to make it more legible
    private func splitIntoGroups(
        _ string : String
    ) -> String {
        var result : String = ""

        if (0 >= MainView.PASSWORD_GROUPS_LENGTH) {
            result = string
        } else {
            for i in stride(from : 0, to : string.count, by : MainView.PASSWORD_GROUPS_LENGTH) {
                // append the next slice
                result.append(string[i..<((i+MainView.PASSWORD_GROUPS_LENGTH <= string.count) ? i+MainView.PASSWORD_GROUPS_LENGTH : string.count)])

                // append a line break or space depending on the number of groups
                result.append((((i / MainView.PASSWORD_GROUPS_LENGTH) + 1) % MainView.PASSWORD_GROUPS_PER_LINE == 0) ? "\n" : " ")
            }
        }

        return result.trimmingCharacters(in : .whitespacesAndNewlines)
    }

    // return a Text field with appropriate formatting
    @ViewBuilder private func PasswordText(
        _ string : String
    ) -> some View {
        Text(string)
            .allowsTightening(true)
            .fixedSize(horizontal : false, vertical : true)
            .font(Font.custom("DejaVuSansMono", size : 16))
            .frame(maxWidth : .infinity, maxHeight : .infinity, alignment : .center)
            .lineLimit(nil)
            .padding(.vertical)
            .textContentType(.password)
    }

    // ===== MAIN INTERFACE TO APP =====

    public var body : some View {
        if (environmentRedactionReasons.contains(.privacy)) {
            PrivacyView($stateUnlocked, $stateUnlockedOnce)
        } else {
            if (!stateUnlocked) {
                PrivacyView($stateUnlocked, $stateUnlockedOnce)
            } else {
                ZStack {
                    Form {
                        Section(header : Text(LocalizedStringKey("Password"))) {
                            SecureField(LocalizedStringKey("Enter Password"), text : $statePassword1)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .font(Font.custom("DejaVuSansMono", size : 16))
                                .keyboardType(.asciiCapable)
                                .textContentType(.password)

                            SecureField(LocalizedStringKey("Repeat Password"), text : $statePassword2)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .font(Font.custom("DejaVuSansMono", size : 16))
                                .keyboardType(.asciiCapable)
                                .textContentType(.password)
                        }

                        Section(header : Text(LocalizedStringKey("Information"))) {
                            TextField(LocalizedStringKey("Enter Information"), text : $stateInformation)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .font(Font.custom("DejaVuSansMono", size : 16))
                                .keyboardType(.asciiCapable)

                            // as buttons in Forms look and behave weirdly
                            // we emulate a button by means of an HStack
                            HStack {
                                Text(LocalizedStringKey("Configuration"))
                                    .foregroundColor(.blue)

                                Spacer()

                                Image(systemName : (stateShowConfiguration) ? "chevron.down" : "chevron.right")
                                    .foregroundColor(.blue)
                            }.contentShape(Rectangle())
                            .onTapGesture {
                                configurationButtonClicked()
                            }

                            if (stateShowConfiguration) {
                                HStack {
                                    Text(LocalizedStringKey("Length"))

                                    TextField(LocalizedStringKey("Enter Length"), text : $stateLength)
                                        .autocapitalization(.none)
                                        .disableAutocorrection(true)
                                        .font(Font.custom("DejaVuSansMono", size : 16))
                                        .keyboardType(.numberPad)
                                        .multilineTextAlignment(.trailing)
                                }

                                HStack {
                                    Text(LocalizedStringKey("Character Set"))

                                    TextField(LocalizedStringKey("Enter Character Set"), text : $stateCharacterset)
                                        .autocapitalization(.none)
                                        .disableAutocorrection(true)
                                        .font(Font.custom("DejaVuSansMono", size : 16))
                                        .keyboardType(.asciiCapable)
                                        .multilineTextAlignment(.trailing)
                                }

                                Toggle(isOn : $stateEnforce) {
                                    Text(LocalizedStringKey("Enforce Character Set"))
                                }

                                // as buttons in Forms look and behave weirdly
                                // we emulate a button by means of an HStack
                                HStack(alignment : .center, spacing : 5) {
                                    Spacer()

                                    Image(systemName : "slider.horizontal.3")
                                        .foregroundColor(isConfigurationModified() ? .blue : .gray)

                                    Text(LocalizedStringKey("Save As Default"))
                                        .foregroundColor(isConfigurationModified() ? .blue : .gray)

                                    Spacer()
                                }.contentShape(Rectangle())
                                .onTapGesture {
                                    saveAsDefaultButtonClicked()
                                }
                            }
                        }

                        Section {
                            // as buttons in Forms look and behave weirdly
                            // we emulate a button by means of an HStack
                            HStack(alignment : .center, spacing : 5) {
                                Spacer()

                                Image(systemName : "lock")
                                    .foregroundColor(isMainViewFormFilledOut() ? .blue : .gray)

                                Text(LocalizedStringKey("Calculate Password"))
                                    .foregroundColor(isMainViewFormFilledOut() ? .blue : .gray)

                                Spacer()
                            }.contentShape(Rectangle())
                            .onTapGesture {
                                calculateButtonClicked()
                            }
                        }

                        if ("" != stateCalculatedPassword) {
                            Section {
                                HStack (alignment : .firstTextBaseline) {
                                    if (!stateCalculationSuccess) {
                                        PasswordText(stateCalculatedPassword)
                                    } else {
                                        if (stateShowPassword) {
                                            PasswordText(splitIntoGroups(stateCalculatedPassword))
                                        } else {
                                            PasswordText(NSLocalizedString("[hidden]", comment : ""))
                                        }
                                    }

                                    if (stateCalculationSuccess) {
                                        Image(systemName : (stateShowPassword) ? "eye.fill" : "eye.slash.fill")
                                        .onTapGesture {
                                            showPasswordButtonClicked()
                                        }
                                    }
                                }.clipped()
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    copyToClipboardButtonClicked()
                                }
                            }

                            if (stateShowPassword) {
                                Section {
                                    if (stateShowQRCode) {
                                        Image(uiImage : UIImage.generateQRCode(stateCalculatedPassword, MainView.QR_CODE_CORRECTION_LEVEL))
                                            .interpolation(.none)
                                            .resizable()
                                            .scaledToFit()
                                    } else {
                                        // as buttons in Forms look and behave weirdly
                                        // we emulate a button by means of an HStack
                                        HStack(alignment : .center, spacing : 5) {
                                            Spacer()

                                            Image(systemName : "qrcode")
                                                .foregroundColor(.blue)

                                            Text(LocalizedStringKey("Generate QR Code"))
                                                .foregroundColor(.blue)

                                            Spacer()
                                        }.contentShape(Rectangle())
                                        .onTapGesture {
                                            showQRCodeButtonClicked()
                                        }
                                    }
                                }
                            }
                        }
                    }.onTapGesture {
                        mainViewFormClicked()
                    }

                    if (stateShowCopiedToClipboard) {
                        MessageView("Copied to Clipboard", "doc.on.clipboard", $stateShowCopiedToClipboard)
                    }
                    if (stateShowSavedAsDefault) {
                        MessageView("Saved As Default", "square.and.arrow.down", $stateShowSavedAsDefault)
                    }
                }.onAppear {
                    mainViewAppeared()
                }.onDisappear {
                    mainViewDisappeared()
                }.statusBar(hidden : false)
                .zIndex(0) // ensure that we are in the back
            }
        }
    }
}

struct MainView_Previews : PreviewProvider {

    public static var previews : some View {
        MainView(true)
    }

}
