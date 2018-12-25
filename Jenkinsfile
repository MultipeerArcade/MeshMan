pipeline {
	agent {
		label 'macos'
	}

	environment {
		PROJECT = "MeshMan.xcodeproj"
		DESTINATION = "'name=iPhone 8'"
		SCHEME = "MeshMan"
		SDK = "iphonesimulator"
		XCB = "set -o pipefail && xcodebuild -project ${PROJECT} -scheme ${SCHEME} -sdk ${SDK} -destination ${DESTINATION}"
		XCP = "| xcpretty -c"
	}

	stages {
		stage('Build') {
			steps {
				sh "${XCB} ${XCP}"
			}
		}
		stage('Test') {
			steps {
				sh "${XCB} test ${XCP}"
			}
		}
	}
}
