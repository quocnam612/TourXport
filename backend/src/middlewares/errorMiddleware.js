const errorMiddleware = (err, req, res, next) => {
    if (res.headersSent) {
        return next(err);
    }

    const statusCode = err.statusCode
        || err.status
        || (err.name === 'ValidationError' || err.name === 'MulterError' ? 400 : 500);

    console.error(err.stack || err);

    res.status(statusCode).json({
        success: false,
        message: err.message || 'Something went wrong on the server!'
    });
};

export default errorMiddleware;
