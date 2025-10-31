import Testing
import UIKit
import OSLog
import Alamofire
@testable import JQSPM
@testable import JQSPM_UI
@available(iOS 14.0, *)
@Test func example() async throws {

//    var req = Request()
//    let reqAuth = ReqAuth(tk: "50ca4661295101c77d44e610d55831dd", keyword: "四川省", childLevel: "0", extensions: "true")
//    req.parameters = reqAuth
//
////        debugPrint(value)
//    await Server().sendRequest(req)

    let result = await ExplorerServer().reqeust()

    switch result {
    case .success(let data):
        for v in data.data{
            debugPrint("\(v.name)")
        }
    case .failure(let failure):
        debugPrint(failure.message ?? "")
    }
}

@Test func weatherReq() async throws {
    if #available(iOS 16.0, *) {
        WeatherServer().getWeather()
    } 
}


struct ExplorerServer:APIBaseService{

    var host: String = "http://127.0.0.1:8080"

    func reqeust() async->Result<ResultResponse,APIError>{
        let reqPage = ReqPage(type: "动物界", page: 1, size: 20, has_poison: 0)
        var req = ExplorerRequest()
        req.parameters = reqPage
        return await sendRequest(req, res: ResultResponse.self)
    }
}

struct ReqPage:Encodable,APIRequestBearerAuthorizable{
    var type:String = ""
    var page:Int = 0
    var size:Int = 0
    var has_poison:Int = 0
}


struct ResultResponse:APIResponse{
    var code:Int = 0
    var data = [ResponsePage]()
    var message:String = ""
    var page:Int = 0
    var size:Int = 0
    var total:Int = 0
}

struct ResponsePage:APIResponse{
    var id:Int = 0
    var name:String = ""
    var cover_URL:String = ""
}


struct ExplorerRequest:APIBearerRequest{
    var parameters: (any Encodable)?
    var uri: String = "/album/query"
    var headers: HTTPHeaders?{
        get{
            ["Auth":accessToken ?? ""]
        }
    }
}

extension APIRequestBearerAuthorizable{
    var accessToken: String? {return ""}
}



