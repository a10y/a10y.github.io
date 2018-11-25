default:
	echo "Use either 'serve' or 'deploy' make commands"
serve:
	hugo server
deploy:
	./deploy.sh
