//
//  Constants.swift
//  PakingGo
//
//  Created by 김학철 on 2021/02/21.
//

/*
1.     로딩 이미지
A.     첨부파일 loging.png
2.     테스트 URL
A.     http://14.192.80.164/AptMobile
B.      로그인 (http://14.192.80.164/AptMobile/User/Logon.aspx)
         i.         아파트명: 아파트
        ii.         동: 101
       iii.         호: 101
       iv.         비밀번호: 1111
3.     푸쉬 메시지
A.     모바일에서 푸시메시지 수신후 클릭시
         i.         http://14.192.80.164/AptMobile/PushMessage/InPushMessage.aspx 호출
        ii.         파라미터 전달 방식: POST
       iii.         파라미터 명: PushMessage
       iv.         파라미터 값: data (푸쉬메시지 수신시의 data-json데이터), 아래 푸쉬 발송시의 data
        v.         푸쉬 발송(실 내용은 조금 달라질 수 있으나, data의 json데이터를 그대로 반환하면 됨.
    {{""registration_ids"":[""{0}""],
        ""data"":{{
                    ""pushType"":""{1}"", ""MP_ID"":""{2}"", ""POSTMB_DEVICE_NAME"":""{3}"", ""DONG"":""{4}"", ""HO"":""{5}""
                    , ""InDay"":""{6}"", ""InTime"":""{7}"", ""VehicleNo"":""{8}"", ""ContentTitle"":""{9}"", ""Message"":""{10}""
                    }}
        , ""priority"":""high""
    }}
4.     로그인 유지
A.     서비스 특성상 로그인 유지 필수, 자동로그인 유무에 의한 로그인 유지
B.      앱 강제 종료에 의한 경우에만 웹 쿠키가 유지 안되는 문제가 있는 것으로 판단되어,
C.      앱 강제 종료 이후 최초 실행시 다음 페이지 호출
    i. 호출URL: http://14.192.80.164/AptMobile/User/LoginCheck.aspx
D.     파라미터 전달 방식: POST
E.      파라미터 명: UserInfo
F.      파라미터 값: 사용자의 로그인 json data(인코딩 데이터를 저장하게됨)
             i.         실데이터:"{\"PLGKey\":null,\"PLKey\":\"parking99\",\"ParkingLotName\":\"아파트\",\"UserTypeCode\":\"P01U02100\",\"UserAuthCode\":null,\"UserID\":\"parking99101101\",\"UserName\":\"101호\",\"UserGroupName\":null,\"UserDong\":\"101\",\"UserHo\":\"101\",\"AllDiscountUseYN\":null}"

            ii.         인코딩데이터: "%7b%22PLGKey%22%3anull%2c%22PLKey%22%3a%22parking99%22%2c%22ParkingLotName%22%3a%22%ec%95%84%ed%8c%8c%ed%8a%b8%22%2c%22UserTypeCode%22%3a%22P01U02100%22%2c%22UserAuthCode%22%3anull%2c%22UserID%22%3a%22parking99101101%22%2c%22UserName%22%3a%22101%ed%98%b8%22%2c%22UserGroupName%22%3anull%2c%22UserDong%22%3a%22101%22%2c%22UserHo%22%3a%22101%22%2c%22AllDiscountUseYN%22%3anull%7d"

G.     특정 페이지에서 로그인 정보 요청
     i.         호출 함수: webkit.GetUserLoginInfo
    ii.         반환 함수: javascript.ReceiveUserLoginInfo(userInfo)

H.     사용자의 자동로그인 설정에 따른 정보 삭제 저장
     i.         호출 함수: webkit.SetUserLoginInfo(userInfo)
    ii.         반환 함수: 없음
   iii.         파라미터 userInfo에 빈 값 또는 로그인정보가 들어가게 되며, 앱에서 저장 후 GetUserLoginInfo호출시 내려주면 됨.
5.     모바일 정보 조회
A.     서비스 특성상 모바일키와 핸드폰 번호를 필수로 받아야 됨.
B.      핸드폰 번호의 경우 배포시 리젝 사유에 의해서 리젝이 된다면 제외 가능
C.      정보 요청
     i.         호출 함수: webkit.GetMobileInfo
    ii.         반환 함수: javascript.RecevieMobileInfo(mobileKey, phoneNum)
6.     Javascript의 alert이 기능

 내용이 다소 많아 보일 수 있으나, 3가지 기능입니다.
혹시, 내용에 문제가 있거나, 프로세스가 이상한 부분이 있으면 회신바랍니다.
수고하세요.
 */
//
//[앱명]:
//    마이파킹 방문예약
//
//[설명]:
//    아파트 입주민의 주차 편의를 위하여 방문예약앱을 서비스하게 되었습니다.
//    실시간으로 방문자의 주차 예약을 함으로써 기다림과 불편함을 해소하며
//    즐겨찾기를 통해 쉽고 빠르게 차량 예약을 할 수 있습니다.
//
//[호출URL]
//    http://apt.myparking.co.kr/aptmobile
//
//[개인정보보호 URL]
//    http://apt.myparking.co.kr/AptMobile/User/PersonalPrivacy.html
//
//[테스트 계정]
//    아파트명: 아파트
//    동: 101
//    호: 101
//    비밀번호: 1111
//

import UIKit
public func RGB(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat) -> UIColor {
    UIColor(red: r / 255.0, green: g / 255.0, blue: b / 255.0, alpha: 1.0)
}
public func RGBA(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat) -> UIColor {
    UIColor(red: r / 255.0, green: g / 255.0, blue: b / 255.0, alpha: a / 1.0)
}
class Constants: NSObject {
    
    struct url {
        static let base = "http://apt.myparking.co.kr/aptmobile" //"http://14.192.80.164/AptMobile"
//http://apt.myparking.co.kr/AptMobile/PushMessage/InPushMessage.aspx?pushType=정기차량&id=12&deviceName=168.126.63.1&vehicleNo=11가1111&inDay=2021-03-10&inTime=21:23:12&dong=101&ho=101&p1=param1&p2=param2&p3=param3
        static let pushRedirect = "http://apt.myparking.co.kr/AptMobile/PushMessage/InPushMessage.aspx"
//        static let pushRedirect = "http://apt.myparking.co.kr/AptMobile/PushMessage/InPushMessageTest.aspx"
//        static let login = "http://14.192.80.164/AptMobile/User/Logon.aspx"
//        static let loginCheck = "http://14.192.80.164/AptMobile/User/LoginCheck.aspx"

        static let test = "http://apt.myparking.co.kr/aptmobile/Support/MobileTest.aspx"
    }
    struct dfsKey {
        static let cookies = "LoginCookiesKey"
        static let userInfo = "UserInfo"
    }
    struct notiName {
        static let pushData = "pushData"
        
    }
    
}
