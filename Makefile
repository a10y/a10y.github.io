default:
	echo "Use either 'serve' or 'deploy' make commands"
serve:
	hugo server -D
deploy:
	./deploy.sh
