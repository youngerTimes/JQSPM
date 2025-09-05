//
//  File.swift
//  JQSPM
//
//  Created by 无故事王国 on 2024/12/20.
//

import Foundation
import CommonCrypto

struct AESEncryptor {

//    static let KEY = ""
//
//    /// 加密
//    public static func encode(to str:String) -> String?{
//        guard let aes = try? AES(key: AESEncryptor.KEY.bytes, blockMode: ECB(),padding: .pkcs5) else{return nil}
//        guard let encrypted = try? aes.encrypt(str.bytes) else { return nil }
//        let encryptedBase64 = encrypted.toBase64()
//        return encryptedBase64
//    }
//
//    /// 解密
//    public static func decode(to str:String) -> String?{
//        guard let aes = try? AES(key: AESEncryptor.KEY.bytes, blockMode: ECB(), padding: .pkcs5) else { return nil }
//        guard let decrypted = try? str.decryptBase64ToString(cipher: aes) else { return nil }
//        return decrypted
//    }
}

extension JQFisher where Base == String{
//    ///AES加密
//    var AESencode:String?{
//        get{return  AESEncryptor.encode(to: self)}
//    }
//
//    ///AES解密
//    var AESdecode:String?{
//        get{return AESEncryptor.decode(to: self)}
//    }


    /// md5
    var md5:String{
        get{
            let str = self.base.cString(using: String.Encoding.utf8)
            let strLen = CUnsignedInt(self.base.lengthOfBytes(using: String.Encoding.utf8))
            let digestLen = Int(CC_MD5_DIGEST_LENGTH)
            let result = UnsafeMutablePointer<CUnsignedChar>.allocate(capacity: digestLen)
            CC_MD5(str!, strLen, result)
            let hash = NSMutableString()
            for i in 0 ..< digestLen {
                hash.appendFormat("%02x", result[i])
            }
            result.deallocate()
            return String(format: hash as String)
        }
    }

    var base64Encoding:String{
        let strData = self.base.data(using: String.Encoding.utf8)
        let base64String = strData?.base64EncodedString(options: NSData.Base64EncodingOptions.init(rawValue: 0))
        return base64String!
    }

    ///解码
    var base64Decoding:String{
        let decodedData = NSData(base64Encoded: self.base, options: NSData.Base64DecodingOptions.init(rawValue: 0))
        let decodedString = NSString(data: decodedData! as Data, encoding: String.Encoding.utf8.rawValue)! as String
        return decodedString
    }

    var  SHA1:String {
        let data = self.base.data(using: String.Encoding.utf8)!
        var digest = [UInt8](repeating: 0, count:Int(CC_SHA1_DIGEST_LENGTH))
        let newData = NSData.init(data: data)
        CC_SHA1(newData.bytes, CC_LONG(data.count), &digest)
        let output = NSMutableString(capacity: Int(CC_SHA1_DIGEST_LENGTH))
        for byte in digest {
            output.appendFormat("%02x", byte)
        }
        return output as String
    }

}

