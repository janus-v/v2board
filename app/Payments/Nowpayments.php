<?php

namespace App\Payments;


/* https://api.nowpayments.io/v1 */
/* 7D3NQYV-FB6MCRT-P8MFDVS-W94NRQ2		 */
/* BlIRTcoeb8N66/PPqTjLAloU5/Mzt2ff  */

/* 
curl --location 'https://api.nowpayments.io/v1/invoice' \
--header 'x-api-key: 7D3NQYV-FB6MCRT-P8MFDVS-W94NRQ2' \
--header 'Content-Type: application/json' \
--data '{
  "price_amount": 1000,
  "price_currency": "usd",
  "order_id": "RGDBP-21314",
  "order_description": "Apple Macbook Pro 2019 x 1",
  "ipn_callback_url": "https://nowpayments.io",
  "success_url": "https://nowpayments.io",
  "cancel_url": "https://nowpayments.io"
}'

*/

class Nowpayments {
    public function __construct($config) {
        $this->config = $config;
    }

    public function form()
    {
        return [
            'url' => [
                'label' => 'URL',
                'description' => '',
                'type' => 'input',
            ],
            'key' => [
                'label' => 'API KEY',
                'description' => '',
                'type' => 'input',
            ],
            'ipn' => [
                'label' => 'IPN',
                'description' => '',
                'type' => 'input',
            ],
        ];
    }

    public function pay($order) {
        /* 
        price_amount (required) - the amount that users have to pay for the order stated in fiat currency. In case you do not indicate the price in crypto, our system will automatically convert this fiat amount into its crypto equivalent. NOTE: Some of the assets (KISHU, NWC, FTT, CHR, XYM, SRK, KLV, SUPER, OM, XCUR, NOW, SHIB, SAND, MATIC, CTSI, MANA, FRONT, FTM, DAO, LGCY), have a maximum price limit of ~$2000;
        price_currency (required) - the fiat currency in which the price_amount is specified (usd, eur, etc);
        pay_currency (optional) - the specified crypto currency (btc, eth, etc), or one of available fiat currencies if it's enabled for your account (USD, EUR, ILS, GBP, AUD, RON);
        If not specified, can be chosen on the invoice_url
        ipn_callback_url (optional) - url to receive callbacks, should contain "http" or "https", eg. "https://nowpayments.io";
        order_id (optional) - internal store order ID, e.g. "RGDBP-21314";
        order_description (optional) - internal store order description, e.g. "Apple Macbook Pro 2019 x 1";
        success_url(optional) - url where the customer will be redirected after successful payment;
        cancel_url(optional) - url where the customer will be redirected after failed payment;
        is_fixed_rate(optional) - boolean, can be true or false. Required for fixed-rate exchanges;
        NOTE: the rate of exchange will be frozen for 20 minutes. If there are no incoming payments during this period, the payment status changes to "expired";
        is_fee_paid_by_user(optional) - boolean, can be true or false. Required for fixed-rate exchanges with all fees paid by users;
        NOTE: the rate of exchange will be frozen for 20 minutes. If there are no incoming payments during this period, the payment status changes to "expired";
        */

        $params = [
            'price_amount' => $order['total_amount'] / 100,
            'price_currency': "usd",
            'order_id' => $order['trade_no'],
            'order_description' => '订单号 ' . $order['trade_no'],
            'ipn_callback_url' => $order['notify_url'],
            'success_url' => $order['return_url'],
            'cancel_url' => $order['return_url']
        ];

        $params_string = json_encode($params);

        $ret_raw = self::_curlPost($this->config['url'] . '/invoice', $params_string);

        $ret = json_decode($ret_raw, true);
        
        if(empty($ret['invoice_url'])) {
            abort(500, "error!");
        }
        return [
            'type' => 1,
            'data' => $ret['invoice_url'],
        ];
    }

    function check_ipn_request_is_valid()
    {
        $error_msg = "Unknown error";
        $auth_ok = false;
        $request_data = null;
        if (isset($_SERVER['HTTP_X_NOWPAYMENTS_SIG']) && !empty($_SERVER['HTTP_X_NOWPAYMENTS_SIG'])) {
            $recived_hmac = $_SERVER['HTTP_X_NOWPAYMENTS_SIG'];
            $request_json = file_get_contents('php://input');
            $request_data = json_decode($request_json, true);
            ksort($request_data);
            $sorted_request_json = json_encode($request_data, JSON_UNESCAPED_SLASHES);
            if ($request_json !== false && !empty($request_json)) {
                $hmac = hash_hmac("sha512", $sorted_request_json, trim($this->ipn_secret));
                if ($hmac == $recived_hmac) {
                    $auth_ok = true;
                } else {
                    $error_msg = 'HMAC signature does not match';
                }
            } else {
                $error_msg = 'Error reading POST data';
            }
        } else {
            $error_msg = 'No HMAC signature sent.';
        }
    }

    public function notify($params) {
        
        $payload = trim(file_get_contents('php://input'));
        $json_param = json_decode($payload, true); 

        $headerName = 'HTTP_X_NOWPAYMENTS_SIG';
        $headers = getallheaders();
        $signatureHeader = isset($headers[$headerName]) ? $headers[$headerName] : '';


        if ($json_param !== false && !empty($json_param)) {
            ksort($json_param);
            $sorted_request_json = json_encode($json_param, JSON_UNESCAPED_SLASHES);

            $computedSignature = hash_hmac("sha512", $sorted_request_json, trim($this->config['ipn']));

            if (!self::hashEqual($signatureHeader, $computedSignature)) {
                abort(400, 'HMAC signature does not match');
            }
        } else {
            abort(400, 'HMAC signature does not match');
        }

        $out_trade_no = $json_param['order_id'];
        $pay_trade_no=$json_param['event']['id'];
        return [
            'trade_no' => $out_trade_no,
            'callback_no' => $pay_trade_no
        ];
        http_response_code(200);
        die('success');
    }


    private function _curlPost($url,$params=false){
        
        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, $url);
        curl_setopt($ch, CURLOPT_HEADER, 0);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
        curl_setopt($ch, CURLOPT_TIMEOUT, 300);
        curl_setopt($ch, CURLOPT_POSTFIELDS, $params);
        curl_setopt(
            $ch, CURLOPT_HTTPHEADER, array('x-api-key: ' .$this->config['key'], 'Content-Type: application/json')
        );
        $result = curl_exec($ch);
        curl_close($ch);
        return $result;
    }


    /**
     * @param string $str1
     * @param string $str2
     * @return bool
     */
    public function hashEqual($str1, $str2)
    {
        if (function_exists('hash_equals')) {
            return \hash_equals($str1, $str2);
        }

        if (strlen($str1) != strlen($str2)) {
            return false;
        } else {
            $res = $str1 ^ $str2;
            $ret = 0;

            for ($i = strlen($res) - 1; $i >= 0; $i--) {
                $ret |= ord($res[$i]);
            }
            return !$ret;
        }
    }
    
}

