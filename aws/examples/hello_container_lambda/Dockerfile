# AWS's base image already includes the Lambda Runtime Interface Client
# (RIC), so no manual RIC install is needed.
FROM public.ecr.aws/lambda/python:3.13

# ${LAMBDA_TASK_ROOT} is /var/task inside the image - where the RIC looks
# for the handler module.
COPY src/hello_world.py ${LAMBDA_TASK_ROOT}

CMD ["hello_world.handler"]
