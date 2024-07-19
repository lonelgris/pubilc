package utils

import (
	"bytes"
	"context"
	"encoding/json"
	"golang.org/x/net/context/ctxhttp"
	"io"
	"net/http"
	"net/url"
	"strings"
	"time"
)

func HttpRequest(ctx context.Context, method string, url string, headers map[string]string, requestBody io.Reader) (responseHeader http.Header, body []byte, err error, returnCode int) {
	req, err := http.NewRequest(method, url, requestBody)
	if err != nil {
		return nil, nil, err, 0
	}

	for k, v := range headers {
		req.Header.Add(k, v)
	}

	ctx, cancel := context.WithTimeout(ctx, 25*time.Second)
	defer cancel()

	resp, err := ctxhttp.Do(ctx, nil, req)
	if err != nil {
		return nil, nil, err, 0
	}

	defer resp.Body.Close()

	body, err = io.ReadAll(resp.Body)
	if err != nil {
		return nil, nil, err, 0
	}

	return resp.Header, body, nil, resp.StatusCode
}

const (
	ContentTypeXWwwFormUrlencodedText = "application/x-www-form-urlencoded"
	ContentTypeJsonText               = "application/json;charset=UTF-8"
)

func BuildHttpBody(contentType string, dataMap map[string]interface{}) (io.Reader, error) {
	var requestBody io.Reader

	if contentType == ContentTypeXWwwFormUrlencodedText {
		var slice1 []string
		for k, v := range dataMap {
			value, ok := v.(string)
			if ok {
				slice1 = append(slice1, k+"="+url.QueryEscape(value))
			}
		}

		requestBody = strings.NewReader(strings.Join(slice1, "&"))
	} else if contentType == ContentTypeJsonText {
		b, err := json.Marshal(dataMap)
		if err != nil {
			return nil, err
		}

		requestBody = bytes.NewBuffer(b)
	}

	return requestBody, nil
}
