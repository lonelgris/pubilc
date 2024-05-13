package main

import (
	"context"
	"errors"
	"fmt"
	"github.com/gin-contrib/static"
	"github.com/gin-gonic/gin"
	"github.com/sirupsen/logrus"
	"math/rand"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"
)

func main() {
	rand.Seed(time.Now().UnixNano())

	gin.SetMode(gin.ReleaseMode)

	router := gin.Default()

	port := 7903

	logrus.Infof("文件服务器启动:%v", port)

	router.Use(static.Serve("/download", static.LocalFile("./download", true)))

	router.HEAD("/download", func(c *gin.Context) {
		name := c.Query("name")

		if name == "" {
			c.JSON(http.StatusBadRequest, gin.H{
				"msg": "name is empty",
			})
			return
		}

		fileName := name

		_, errByOpenFile := os.Open(fileName)
		//非空处理
		if errByOpenFile != nil {
			c.JSON(http.StatusOK, gin.H{
				"success": false,
				"message": fmt.Sprintf("文件不存在:%v", fileName),
				"error":   "资源不存在",
			})
			return
		}

		c.Header("Content-Type", "application/octet-stream")
		c.Header("Content-Disposition", "attachment; filename="+name)
		c.Header("Content-Transfer-Encoding", "binary")
		c.File(fileName)
	})

	router.GET("/download", func(c *gin.Context) {
		name := c.Query("name")

		if name == "" {
			c.JSON(http.StatusBadRequest, gin.H{
				"msg": "name is empty",
			})
			return
		}

		fileName := name

		_, errByOpenFile := os.Open(fileName)
		//非空处理
		if errByOpenFile != nil {
			c.JSON(http.StatusOK, gin.H{
				"success": false,
				"message": fmt.Sprintf("文件不存在:%v", fileName),
				"error":   "资源不存在",
			})
			return
		}

		c.Header("Content-Type", "application/octet-stream")
		c.Header("Content-Disposition", "attachment; filename="+name)
		c.Header("Content-Transfer-Encoding", "binary")
		c.File(fileName)
	})

	srv := &http.Server{
		Addr:    fmt.Sprintf(":%v", port),
		Handler: router,
	}

	go func() {

		logrus.Infof("https server start at :%v", port)

		if err := srv.ListenAndServeTLS("conf/test46.sgameuser.com.pem", "conf/test46.sgameuser.com.key"); err != nil {
			if !errors.Is(err, http.ErrServerClosed) {
				logrus.WithError(err).WithField("port", port).Errorf("服务器监听失败")
			}
		}

		logrus.Infof("httpServer closed")
	}()
	quit := make(chan os.Signal)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit
	logrus.Infof("Shutdown Server ...")

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	if err := srv.Shutdown(ctx); err != nil {
		logrus.WithError(err).Errorf("Server Shutdown error")
	}
}
