#include <opencv2/core.hpp>
#include <opencv2/highgui.hpp>
#include <iostream>

// Exercises the Qt6 highgui backend end-to-end (window creation, event pump,
// teardown) under Qt's offscreen QPA platform so it can run headless in CI.
int main() {
    cv::Mat img(64, 64, CV_8UC3, cv::Scalar(240, 240, 240));
    cv::imshow("qt6_smoke_test", img);
    cv::waitKey(1000);
    cv::destroyAllWindows();
    std::cout << "qt6 highgui smoke test OK" << std::endl;
    return 0;
}
